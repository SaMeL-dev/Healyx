package com.smu.healyx.hospital.service;

import com.smu.healyx.agent.dto.HospitalAssistantRequest;
import com.smu.healyx.agent.dto.HospitalAssistantResponse;
import com.smu.healyx.agent.service.HospitalAgentService;
import com.smu.healyx.cost.dto.CostPredictRequest;
import com.smu.healyx.cost.dto.CostPredictResponse;
import com.smu.healyx.cost.service.CostPredictionService;
import com.smu.healyx.hira.dto.HospitalDto;
import com.smu.healyx.hira.dto.HospitalSearchResponse;
import com.smu.healyx.hospital.domain.Hospital;
import com.smu.healyx.hospital.dto.BodyIconResponse;
import com.smu.healyx.hospital.dto.HospitalCardDto;
import com.smu.healyx.hospital.dto.HospitalRecommendRequest;
import com.smu.healyx.hospital.dto.HospitalRecommendResponse;
import com.smu.healyx.hospital.repository.HospitalRepository;
import com.smu.healyx.user.dto.UserProfileDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

@Slf4j
@Service
@RequiredArgsConstructor
public class HospitalRecommendService {

    private final HospitalAgentService    hospitalAgentService;
    private final HospitalRepository      hospitalRepository;
    private final BodyIconService         bodyIconService;
    private final CostPredictionService   costPredictionService;
    private final HospitalScoringService  hospitalScoringService;

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
     * AI Agent 기반 병원 추천 + 카드별 의료비 예측 통합 처리 (HX_H_008 + HX_C_002~003).
     *
     * <p>처리 흐름:
     * <ol>
     *   <li>GPT Agent → HIRA dgsbjtCd 결정 + ICD-10 코드 추출 + 병원 검색</li>
     *   <li>정렬(추천순/거리순) 후 상위 5개 제한 (HOS-008)</li>
     *   <li>hospitals 테이블 ykiho 기준 upsert (OCR 대조 선행 조건)</li>
     *   <li>카드별 의료비 예측 호출 → minCost·maxCost·visitType 적재 (게스트 포함)</li>
     * </ol>
     *
     * <p>게스트 처리 정책 (PM 합의 2026-05-08 2차):
     * 비보험자 기준 의료비 + 나이/성별 보정계수 1.0 + 종별·지역·물가 보정 정상 적용.
     * 결과는 ±25% 신뢰구간으로 반환. 단독 엔드포인트 폐지로 인한 화면설계서
     * UI-HOS-07-G "의료보험 미적용 안내 아이콘" 정합 복구.
     *
     * <p>cost_predictions 저장: 카드 5건 모두 저장(이력 보존). 게스트는
     * user_id=NULL로 저장(의료비예측 API 설계서 1.2 정합).
     *
     * @param request     Flutter 요청 (증상·위치·위험도·정렬)
     * @param userProfile 사용자 프로필 (로그인 시 DB 조회 결과, 게스트 시 default)
     * @param userId      로그인 사용자 PK (게스트는 null)
     */
    @Transactional
    public HospitalRecommendResponse recommend(
            HospitalRecommendRequest request,
            UserProfileDto userProfile,
            Long userId) {

        // ── 1. AI Agent 호출 ─────────────────────────────────────────
        HospitalAssistantRequest agentRequest = buildAgentRequest(request);
        HospitalAssistantResponse agentResponse =
                hospitalAgentService.run(agentRequest, userProfile);

        HospitalSearchResponse searchResponse = agentResponse.getHospitals();
        boolean hasResult = searchResponse != null && !searchResponse.getHospitals().isEmpty();
        List<HospitalDto> hospitals = hasResult ? searchResponse.getHospitals() : List.of();

        // ── 2. hospitals 테이블 upsert (전체, 스코어링 전에 hospitalId 확보) ──
        Map<String, Long> ykihoToHospitalId = Map.of();
        if (hasResult) {
            ykihoToHospitalId = upsertHospitals(hospitals);
        }

        // ── 3. 스코어링 ────────────────────────────────────────────────
        Map<String, HospitalScoringService.ScoredHospital> scoredMap = Map.of();
        if (hasResult) {
            scoredMap = hospitalScoringService.score(
                    hospitals, ykihoToHospitalId, request.getEffectiveRiskLevel());
        }

        // ── 4. 정렬 + 상위 5개 제한 (HOS-008) ─────────────────────────
        if (hasResult) {
            final Map<String, HospitalScoringService.ScoredHospital> finalScoredMap = scoredMap;
            if ("distance".equals(request.getEffectiveSortBy())) {
                hospitals = hospitals.stream()
                        .sorted(Comparator.comparingInt(HospitalDto::getDistance))
                        .limit(5)
                        .collect(Collectors.toList());
            } else {
                // recommend: score DESC 정렬
                hospitals = hospitals.stream()
                        .sorted(Comparator.comparingDouble(
                                (HospitalDto h) -> {
                                    HospitalScoringService.ScoredHospital s = finalScoredMap.get(h.getYkiho());
                                    return s != null ? s.score() : 0.0;
                                }).reversed())
                        .limit(5)
                        .collect(Collectors.toList());
            }
        }

        // ── 5. 카드별 의료비 예측 + 카드 조립 ─────────────────────────
        List<HospitalCardDto> cards = hasResult
                ? buildCards(hospitals, agentResponse, request, userProfile, userId, scoredMap)
                : List.of();

        String emptyReason = hasResult ? null :
                agentResponse.getDepartmentName()
                + " 진료과 병원을 찾을 수 없습니다. 증상을 다시 확인해 주세요.";

        return HospitalRecommendResponse.builder()
                .departmentCode(agentResponse.getDepartmentCode())
                .departmentName(agentResponse.getDepartmentName())
                .icd10Code(agentResponse.getIcd10Code())
                .hospitals(cards)
                .totalCount(hasResult ? searchResponse.getTotalCount() : 0)
                .hasResult(hasResult)
                .emptyReason(emptyReason)
                .build();
    }

    // ── private 헬퍼 ───────────────────────────────────────────────────

    /**
     * 카드 목록 조립.
     *
     * <p>모든 사용자(로그인·게스트)에 대해 카드별 {@link CostPredictionService#predict}
     * 호출. CostPredictionService 내부에서 게스트 여부에 따라 자동 분기:
     * <ul>
     *   <li>로그인 + 보험가입: insurance_avg_cost × 연령·성별·종별·지역·물가 보정</li>
     *   <li>로그인 + 미가입: no_insurance_avg_cost × 연령·성별·종별·지역·물가 보정</li>
     *   <li>게스트: no_insurance_avg_cost × 1.0(연령·성별) × 종별·지역·물가 보정</li>
     * </ul>
     *
     * <p>5개 호출 중 일부 실패해도 전체는 정상 응답하며, 실패 카드는 cost 필드 null +
     * {@code costUnavailableReason} 표시. 흔한 실패 사유: 희귀 ICD-10에 대한
     * cost_reference 미매칭, DB 일시 오류 등.
     *
     * <p>Flutter는 사용자 자신의 로그인·보험 가입 상태를 이미 알고 있으므로,
     * UI-HOS-07-G의 "의료보험 미적용 안내 아이콘" 분기는 클라이언트 자체 상태로
     * 처리한다. 서버는 별도 플래그를 응답에 포함하지 않는다.
     */
    /**
     * 카드 목록 조립 (병렬 처리).
     *
     * <p>5개 카드에 대해 {@link CostPredictionService#predict}를
     * {@code CompletableFuture.supplyAsync} × 5건으로 병렬 발사 후
     * {@code CompletableFuture.allOf().join()}으로 합류한다.
     * ForkJoinPool.commonPool() 사용 (5개 task는 commonPool로 충분).
     *
     * <p>카드 순서는 입력 hospitals 순서 그대로 보존.
     * 단일 카드 예외는 기존과 동일하게 graceful degradation.
     * {@link CostPredictionService}는 {@code @Transactional(REQUIRES_NEW)}이므로
     * 병렬 호출 시에도 트랜잭션 충돌 없음.
     */
    private List<HospitalCardDto> buildCards(List<HospitalDto> hospitals,
                                             HospitalAssistantResponse agent,
                                             HospitalRecommendRequest request,
                                             UserProfileDto userProfile,
                                             Long userId,
                                             Map<String, HospitalScoringService.ScoredHospital> scoredMap) {

        @SuppressWarnings("unchecked")
        CompletableFuture<HospitalCardDto>[] futures =
                new CompletableFuture[hospitals.size()];

        for (int i = 0; i < hospitals.size(); i++) {
            final HospitalDto h = hospitals.get(i);
            futures[i] = CompletableFuture.supplyAsync(() -> {
                // 스코어링 결과 조회
                HospitalScoringService.ScoredHospital scored = scoredMap.get(h.getYkiho());
                double cardScore      = (scored != null) ? scored.score() : 0.0;
                Double cardAvgRating  = (scored != null) ? scored.avgRating() : null;
                int cardReviewCount   = (scored != null) ? scored.reviewCount() : 0;

                try {
                    CostPredictRequest costReq = CostPredictRequest.builder()
                            .icd10Code(agent.getIcd10Code())
                            .departmentName(agent.getDepartmentName())
                            .riskLevel(request.getEffectiveRiskLevel())
                            .hospitalType(h.getClCd())
                            .sidoCdNm(h.getSidoCdNm())
                            .build();

                    CostPredictResponse cost = costPredictionService.predict(
                            costReq, userProfile, userId);

                    return HospitalCardDto.of(
                            h, cost.getMinCost(), cost.getMaxCost(), cost.getVisitType(), null,
                            cardScore, cardAvgRating, cardReviewCount);

                } catch (Exception e) {
                    // 단일 카드 예측 실패가 전체 추천 응답을 막지 않도록 graceful degradation.
                    // 흔한 사유: cost_reference 미매칭(희귀 ICD-10), DB 일시 오류 등.
                    log.warn("카드 의료비 예측 실패 ykiho={} icd10={} : {}",
                            h.getYkiho(), agent.getIcd10Code(), e.getMessage());

                    String reason = (e.getClass().getSimpleName().contains("AuthException"))
                            ? "COST_REFERENCE_NOT_FOUND"
                            : "COST_PREDICT_ERROR";

                    return HospitalCardDto.of(h, null, null, null, reason,
                            cardScore, cardAvgRating, cardReviewCount);
                }
            });
        }

        // 모든 카드 완료 대기 후 입력 순서 그대로 수집
        CompletableFuture.allOf(futures).join();

        return IntStream.range(0, futures.length)
                .mapToObj(i -> futures[i].join())
                .collect(Collectors.toList());
    }

    /**
     * HIRA 응답 병원 목록을 hospitals 테이블에 ykiho 기준으로 upsert.
     * - 기존 행: HIRA 최신 데이터로 갱신 (이름·주소·좌표·인증여부)
     * - 신규 행: INSERT
     *
     * <p>N+1 제거: findByYkiho 5회 → findAllByYkihoIn 1회 IN 쿼리 후
     * ykiho → Hospital Map 구성. 신규/기존 분기 후 saveAll 일괄 저장.
     *
     * @return ykiho → hospitalId 매핑 (스코어링 서비스에서 리뷰 집계 쿼리에 사용)
     */
    private Map<String, Long> upsertHospitals(List<HospitalDto> dtos) {
        List<String> ykihos = dtos.stream()
                .map(HospitalDto::getYkiho)
                .filter(y -> y != null && !y.isBlank())
                .collect(Collectors.toList());

        if (ykihos.isEmpty()) return Map.of();

        Map<String, Hospital> existing = hospitalRepository.findAllByYkihoIn(ykihos)
                .stream()
                .collect(Collectors.toMap(Hospital::getYkiho, Function.identity()));

        List<Hospital> toSave = new ArrayList<>();
        for (HospitalDto dto : dtos) {
            if (dto.getYkiho() == null || dto.getYkiho().isBlank()) continue;

            Hospital hospital = existing.get(dto.getYkiho());
            if (hospital != null) {
                hospital.updateFromHira(dto);
                toSave.add(hospital);
            } else {
                toSave.add(Hospital.fromHiraDto(dto));
            }
        }

        List<Hospital> saved = hospitalRepository.saveAll(toSave);
        log.debug("hospitals upsert 완료: {}건", saved.size());

        return saved.stream()
                .filter(h -> h.getYkiho() != null)
                .collect(Collectors.toMap(Hospital::getYkiho, Hospital::getHospitalId));
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
