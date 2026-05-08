package com.smu.healyx.hospital.service;

import com.smu.healyx.agent.dto.HospitalAssistantRequest;
import com.smu.healyx.agent.dto.HospitalAssistantResponse;
import com.smu.healyx.agent.service.HospitalAgentService;
import com.smu.healyx.hira.dto.HospitalDto;
import com.smu.healyx.hira.dto.HospitalSearchResponse;
import com.smu.healyx.hospital.domain.Hospital;
import com.smu.healyx.hospital.dto.BodyIconResponse;
import com.smu.healyx.hospital.dto.HospitalRecommendRequest;
import com.smu.healyx.hospital.dto.HospitalRecommendResponse;
import com.smu.healyx.hospital.repository.HospitalRepository;
import com.smu.healyx.user.dto.UserProfileDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class HospitalRecommendService {

    private final HospitalAgentService hospitalAgentService;
    private final HospitalRepository hospitalRepository;
    private final BodyIconService bodyIconService;

    /**
     * 신체 부위 아이콘 → 증상 키워드 매핑 (HX_H_002, UI-HOS-05).
     *
     * <p>프로그램 목록(v1.0)이 명시한 메소드 시그니처를 보존하기 위한 위임 메소드.
     * 정적 매핑 책임은 {@link BodyIconService}로 분리되어 있으며 본 메소드는
     * 외부 인터페이스 안정성과 SRP 양쪽을 동시에 만족시킨다.
     */
    public BodyIconResponse mapBodyIconToKeyword(String iconId) {
        return bodyIconService.getKeywords(iconId);
    }

    /**
     * AI Agent를 통해 증상을 분석하고 HIRA API 기반으로 병원을 추천합니다.
     *
     * - 진료과 결정: GPT Agent가 증상을 분석하여 HIRA dgsbjtCd 추출
     * - 위험도(riskLevel): 사용자 슬라이더 입력값 → Agent 내부에서 clCd·반경으로 변환
     * - ICD-10 코드: GPT Agent가 동시 추출 → 의료비 예측(COST) 모듈에서 활용
     * - hospitals 테이블 upsert: 추천된 병원을 ykiho 기준으로 저장 (OCR 대조 선행 조건)
     */
    @Transactional
    public HospitalRecommendResponse recommend(
            HospitalRecommendRequest request, UserProfileDto userProfile) {

        HospitalAssistantRequest agentRequest = buildAgentRequest(request);
        HospitalAssistantResponse agentResponse =
                hospitalAgentService.run(agentRequest, userProfile);

        HospitalSearchResponse searchResponse = agentResponse.getHospitals();
        boolean hasResult = searchResponse != null && !searchResponse.getHospitals().isEmpty();
        List<HospitalDto> hospitals = hasResult ? searchResponse.getHospitals() : List.of();

        // HOS-008: 정렬 적용 후 상위 5개 제한
        if (hasResult) {
            if ("distance".equals(request.getEffectiveSortBy())) {
                hospitals = hospitals.stream()
                        .sorted(Comparator.comparingInt(HospitalDto::getDistance))
                        .limit(5)
                        .collect(Collectors.toList());
            } else {
                hospitals = hospitals.stream()
                        .limit(5)
                        .collect(Collectors.toList());
            }
        }

        // 추천 결과 hospitals 테이블 upsert
        // OCR 인증 시 ykiho 기준 병원명 대조를 위한 선행 조건.
        // ykiho가 없는 항목은 건너뜀.
        if (hasResult) {
            upsertHospitals(hospitals);
        }

        String emptyReason = hasResult ? null :
                agentResponse.getDepartmentName()
                + " 진료과 병원을 찾을 수 없습니다. 증상을 다시 확인해 주세요.";

        return HospitalRecommendResponse.builder()
                .departmentCode(agentResponse.getDepartmentCode())
                .departmentName(agentResponse.getDepartmentName())
                .icd10Code(agentResponse.getIcd10Code())
                .hospitals(hospitals)
                .totalCount(hasResult ? searchResponse.getTotalCount() : 0)
                .hasResult(hasResult)
                .emptyReason(emptyReason)
                .build();
    }

    /**
     * HIRA 응답 병원 목록을 hospitals 테이블에 ykiho 기준으로 upsert한다.
     * - 기존 행: HIRA 최신 데이터로 갱신 (이름·주소·좌표·인증여부)
     * - 신규 행: INSERT
     * 5건 이하라 N+1 부담 없음.
     */
    private void upsertHospitals(List<HospitalDto> dtos) {
        for (HospitalDto dto : dtos) {
            if (dto.getYkiho() == null || dto.getYkiho().isBlank()) continue;

            hospitalRepository.findByYkiho(dto.getYkiho())
                    .ifPresentOrElse(
                            existing -> existing.updateFromHira(dto),
                            () -> hospitalRepository.save(Hospital.fromHiraDto(dto))
                    );
        }
        log.debug("hospitals upsert 완료: {}건", dtos.size());
    }

    /**
     * HospitalRecommendRequest → HospitalAssistantRequest 변환.
     * riskLevel이 null이면 getEffectiveRiskLevel()이 기본값 2 반환.
     */
    private HospitalAssistantRequest buildAgentRequest(HospitalRecommendRequest request) {
        return HospitalAssistantRequest.of(
                request.getSymptom(),
                request.getEffectiveRiskLevel(),
                request.getLatitude(),
                request.getLongitude()
        );
    }
}
