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
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class HospitalRecommendService {

    private final HospitalAgentService    hospitalAgentService;
    private final HospitalRepository      hospitalRepository;
    private final BodyIconService         bodyIconService;
    private final CostPredictionService   costPredictionService;

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
     *   <li>로그인 사용자: 카드별 의료비 예측 호출 → minCost·maxCost·visitType 적재</li>
     *   <li>게스트 사용자: cost 필드 null, costUnavailableReason="GUEST_NOT_LOGGED_IN"</li>
     * </ol>
     *
     * <p>cost_predictions 저장: PM 합의에 따라 카드 5개 모두 저장(이력 보존).
     * 단, 게스트는 의료비 예측 자체를 미수행하므로 저장 0건.
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

        // ── 2. 정렬 + 상위 5개 제한 (HOS-008) ─────────────────────────
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

        // ── 3. hospitals 테이블 upsert (OCR 대조 선행 조건) ──────────
        if (hasResult) {
            upsertHospitals(hospitals);
        }

        // ── 4. 카드별 의료비 예측 + 카드 조립 ─────────────────────────
        List<HospitalCardDto> cards = hasResult
                ? buildCards(hospitals, agentResponse, request, userProfile, userId)
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
     * <p>로그인 사용자: 병원별로 {@link CostPredictionService#predict}를 호출하여
     * minCost·maxCost·visitType을 카드에 적재. 5개 호출 중 일부 실패해도 전체는
     * 정상 응답하며, 실패 카드는 cost 필드 null + reason 표시.
     *
     * <p>게스트 사용자: 의료비 예측 미수행. 모든 카드 cost 필드 null +
     * reason="GUEST_NOT_LOGGED_IN". Flutter는 이 reason 또는 minCost==null로
     * UI-HOS-07-G의 "의료보험 미적용 안내 아이콘" 분기를 수행.
     */
    private List<HospitalCardDto> buildCards(List<HospitalDto> hospitals,
                                             HospitalAssistantResponse agent,
                                             HospitalRecommendRequest request,
                                             UserProfileDto userProfile,
                                             Long userId) {

        boolean isGuest = (userId == null);
        List<HospitalCardDto> cards = new ArrayList<>(hospitals.size());

        for (HospitalDto h : hospitals) {
            if (isGuest) {
                cards.add(HospitalCardDto.of(h, null, null, null, "GUEST_NOT_LOGGED_IN"));
                continue;
            }

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

                cards.add(HospitalCardDto.of(
                        h, cost.getMinCost(), cost.getMaxCost(), cost.getVisitType(), null));

            } catch (Exception e) {
                // 단일 카드 예측 실패가 전체 추천 응답을 막지 않도록 graceful degradation.
                // 흔한 사유: cost_reference 미매칭(희귀 ICD-10), DB 일시 오류 등.
                log.warn("카드 의료비 예측 실패 ykiho={} icd10={} : {}",
                        h.getYkiho(), agent.getIcd10Code(), e.getMessage());

                String reason = (e.getClass().getSimpleName().contains("AuthException"))
                        ? "COST_REFERENCE_NOT_FOUND"
                        : "COST_PREDICT_ERROR";

                cards.add(HospitalCardDto.of(h, null, null, null, reason));
            }
        }

        return cards;
    }

    /**
     * HIRA 응답 병원 목록을 hospitals 테이블에 ykiho 기준으로 upsert.
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
