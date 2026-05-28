package com.smu.healyx.agent.service;

import com.smu.healyx.agent.dto.HospitalAssistantRequest;
import com.smu.healyx.agent.dto.HospitalAssistantResponse;
import com.smu.healyx.gpt.dto.SymptomAnalysisResponse;
import com.smu.healyx.gpt.service.GptService;
import com.smu.healyx.hira.dto.HospitalDto;
import com.smu.healyx.hira.dto.HospitalSearchRequest;
import com.smu.healyx.hira.dto.HospitalSearchResponse;
import com.smu.healyx.hira.service.HiraApiService;
import com.smu.healyx.hospital.domain.ForeignCertifiedHospital;
import com.smu.healyx.hospital.repository.ForeignCertifiedHospitalRepository;
import com.smu.healyx.user.dto.UserProfileDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

/**
 * GPT 단일 호출 + HIRA API 병렬 호출 기반 병원 탐색 서비스.
 *
 * 역할 분담:
 *   GPT  → 증상 분석하여 HIRA 진료과목 코드(dgsbjtCd) + ICD-10 코드 동시 추출 (단일 호출)
 *   서버 → 위험도(1-5)를 병원 종별 범위(clCd 목록)·반경으로 변환,
 *          clCd별 HIRA API 병렬 호출 후 병합·중복 제거
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class HospitalAgentService {

    private final GptService gptService;
    private final HiraApiService hiraApiService;
    private final ForeignCertifiedHospitalRepository foreignCertifiedHospitalRepository;

    /**
     * 위험도별 병원 종별 범위 (낮은 단계일수록 더 많은 종별 포함)
     *
     *   1: 의원 ~ 상급종합 [31, 21, 11, 01]
     *   2: 의원 ~ 상급종합 [31, 21, 11, 01]
     *   3: 병원 ~ 상급종합 [21, 11, 01]
     *   4: 종합병원 ~ 상급종합 [11, 01]
     *   5: 상급종합만 [01]
     */
    public static final Map<Integer, List<String>> RISK_TO_CL_CDS = Map.of(
            1, List.of("31", "21", "11", "01"),
            2, List.of("31", "21", "11", "01"),
            3, List.of("21", "11", "01"),
            4, List.of("11", "01"),
            5, List.of("01")
    );

    /** 위험도별 검색 반경 (m): 1~2단계 3km, 3~4단계 10km, 5단계 15km */
    public static final Map<Integer, Integer> RISK_TO_RADIUS = Map.of(
            1, 3000,
            2, 3000,
            3, 10000,
            4, 10000,
            5, 15000
    );

    /**
     * GPT 단일 호출로 증상 분석 후 HIRA API를 병렬 호출하여 병원 목록을 반환합니다.
     *
     * 개선 전: GPT Function Calling 왕복 2회 이상 + HIRA 순차 호출 (최대 4회)
     * 개선 후: GPT 단일 호출 + HIRA 병렬 호출 → 전체 응답 시간 대폭 단축
     */
    public HospitalAssistantResponse run(HospitalAssistantRequest req, UserProfileDto userProfile) {
        // 1. GPT 단일 호출: 진료과 코드 + ICD-10 동시 추출
        SymptomAnalysisResponse analysis = gptService.extractSymptomInfo(req.getSymptom());
        log.debug("증상 분석 완료: dgsbjtCd={}, dept={}, icd10={}",
                analysis.getDgsbjtCd(), analysis.getDepartmentName(), analysis.getIcd10Code());

        // 2. HIRA API 병렬 호출
        HospitalSearchResponse hospitals = searchAcrossHospitalTypes(analysis.getDgsbjtCd(), req);

        return HospitalAssistantResponse.builder()
                .departmentCode(analysis.getDgsbjtCd())
                .departmentName(analysis.getDepartmentName())
                .hospitals(hospitals)
                .icd10Code(analysis.getIcd10Code())
                .build();
    }

    // ── 다중 병원 종별 HIRA 병렬 호출 + 병합 ─────────────────────────────

    /**
     * 위험도에 해당하는 clCd 목록에 대해 HIRA API를 병렬 호출하고
     * ykiho 기준으로 중복을 제거한 뒤 병합합니다.
     *
     * futures 리스트를 clCds 삽입 순서대로 처리하여
     * putIfAbsent가 올바른 clCd 우선순위(예: "31" > "21")를 유지합니다.
     */
    private HospitalSearchResponse searchAcrossHospitalTypes(
            String dgsbjtCd, HospitalAssistantRequest req) {

        List<String> clCds = RISK_TO_CL_CDS.getOrDefault(req.getRiskLevel(), List.of("31", "21", "11", "01"));
        int radius         = RISK_TO_RADIUS.getOrDefault(req.getRiskLevel(), 3000);

        // clCd별 HIRA 호출을 병렬로 발사 (clCds 순서 유지)
        List<CompletableFuture<Optional<HospitalSearchResponse>>> futures = clCds.stream()
                .map(clCd -> CompletableFuture.supplyAsync(() -> {
                    try {
                        HospitalSearchRequest searchReq = buildSearchRequest(dgsbjtCd, clCd, radius, req);
                        HospitalSearchResponse result = hiraApiService.searchHospitals(searchReq);
                        log.debug("HIRA 조회 완료: clCd={}, 건수={}", clCd, result.getTotalCount());
                        return Optional.of(result);
                    } catch (Exception e) {
                        log.warn("clCd={} 병원 검색 실패 (건너뜀): {}", clCd, e.getMessage());
                        return Optional.<HospitalSearchResponse>empty();
                    }
                }))
                .collect(Collectors.toList());

        // 모든 병렬 호출 완료 대기
        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();

        // clCds 순서대로 결과 병합 (putIfAbsent로 clCd 우선순위 유지)
        Map<String, HospitalDto> merged = new LinkedHashMap<>();
        int totalCount = 0;

        for (CompletableFuture<Optional<HospitalSearchResponse>> future : futures) {
            Optional<HospitalSearchResponse> result = future.join();
            if (result.isPresent()) {
                totalCount += result.get().getTotalCount();
                for (HospitalDto hospital : result.get().getHospitals()) {
                    if (hospital.getYkiho() != null) {
                        merged.putIfAbsent(hospital.getYkiho(), hospital);
                    }
                }
            }
        }

        if (merged.isEmpty()) {
            log.warn("dgsbjtCd={}, riskLevel={}: 모든 clCd 검색 결과 없음", dgsbjtCd, req.getRiskLevel());
            return HospitalSearchResponse.builder()
                    .hospitals(List.of())
                    .pageNo(1)
                    .numOfRows(0)
                    .totalCount(0)
                    .build();
        }

        // 단일 IN 쿼리로 인증 병원 ykiho Set 확보 (N+1 방지)
        Set<String> certifiedYkihos = foreignCertifiedHospitalRepository
                .findAllByYkihoIn(merged.keySet())
                .stream()
                .map(ForeignCertifiedHospital::getYkiho)
                .collect(Collectors.toSet());

        List<HospitalDto> hospitals = merged.values().stream()
                .map(dto -> HospitalDto.builder()
                        .ykiho(dto.getYkiho())
                        .hospitalName(dto.getHospitalName())
                        .address(dto.getAddress())
                        .telephone(dto.getTelephone())
                        .longitude(dto.getLongitude())
                        .latitude(dto.getLatitude())
                        .distance(dto.getDistance())
                        .clCd(dto.getClCd())
                        .hospitalType(dto.getHospitalType())
                        .sidoCd(dto.getSidoCd())
                        .sidoCdNm(dto.getSidoCdNm())
                        .foreignCertified(certifiedYkihos.contains(dto.getYkiho()))
                        .build())
                .collect(Collectors.toList());

        return HospitalSearchResponse.builder()
                .hospitals(hospitals)
                .pageNo(1)
                .numOfRows(hospitals.size())
                .totalCount(totalCount)
                .build();
    }

    private HospitalSearchRequest buildSearchRequest(
            String dgsbjtCd, String clCd, int radius, HospitalAssistantRequest req) {

        HospitalSearchRequest r = new HospitalSearchRequest();
        r.setDgsbjtCd(dgsbjtCd);
        r.setClCd(clCd);
        r.setXPos(req.getLongitude());
        r.setYPos(req.getLatitude());
        r.setRadius(radius);
        return r;
    }
}
