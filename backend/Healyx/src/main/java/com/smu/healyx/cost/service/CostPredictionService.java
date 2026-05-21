package com.smu.healyx.cost.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.cost.domain.CostAdjustment;
import com.smu.healyx.cost.domain.CostPrediction;
import com.smu.healyx.cost.domain.CostReference;
import com.smu.healyx.cost.dto.CostPredictRequest;
import com.smu.healyx.cost.dto.CostPredictResponse;
import com.smu.healyx.cost.repository.CostAdjustmentRepository;
import com.smu.healyx.cost.repository.CostPredictionRepository;
import com.smu.healyx.cost.repository.CostReferenceRepository;
import com.smu.healyx.cost.repository.HospitalTypeAdjustmentRepository;
import com.smu.healyx.cost.repository.RegionAdjustmentRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.dto.UserProfileDto;
import com.smu.healyx.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class CostPredictionService {

    private static final double INFLATION_FACTOR = 1.061;
    private static final double CONFIDENCE_MIN   = 0.75;
    private static final double CONFIDENCE_MAX   = 1.25;

    private final CostReferenceRepository          costReferenceRepository;
    private final CostAdjustmentRepository         costAdjustmentRepository;
    private final HospitalTypeAdjustmentRepository hospitalTypeAdjustmentRepository;
    private final RegionAdjustmentRepository       regionAdjustmentRepository;
    private final CostPredictionRepository         costPredictionRepository;
    private final UserRepository                   userRepository;

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public CostPredictResponse predict(
            CostPredictRequest req,
            UserProfileDto profile,
            Long userId) {

        // ── 1. 입력값 검증 ──────────────────────────────────────────
        if (req.hasNoCostBasis()) {
            throw new AuthException(
                    "COST_BASIS_MISSING",
                    "증상 코드 또는 진료과명이 필요합니다.",
                    HttpStatus.BAD_REQUEST);
        }

        // ── 2. visit_type 결정 ─────────────────────────────────────
        String visitType = resolveVisitType(req.getRiskLevel());

        // ── 3. 기준 수가 조회 ──────────────────────────────────────
        CostReference reference = resolveCostReference(req, visitType);

        // ── 4. 보험 여부 결정 ──────────────────────────────────────
        boolean insured = resolveInsured(req, profile);

        // ── 5. 기준 수가 (전액 기준으로 통일) ─────────────────────
        double baseCost = reference.getNoInsuranceAvgCost();

        // ── 6. 연령·성별 보정 (adj_factor_full 사용) ───────────────
        double ageGenderFactor = resolveAgeGenderFactor(req, profile);

        // ── 7. 지역 보정 (sidoCdNm + departmentName 기반 region_adjustment 조회) ─
        // region_adjustment 미적재 또는 미매칭 시 1.0 fallback 자동 처리.
        double regionFactor = resolveRegionFactor(req.getSidoCdNm(), req.getDepartmentName());

        // ── 8. 병원 종별 보정 ──────────────────────────────────────
        double hospitalTypeFactor = resolveHospitalTypeFactor(req.getHospitalType());

        // ── 9. 보험 가입자 본인부담률 적용 ────────────────────────
        double insuranceFactor = 1.0;
        if (insured && reference.getNoInsuranceAvgCost() > 0) {
            insuranceFactor = (double) reference.getInsuranceAvgCost()
                    / reference.getNoInsuranceAvgCost();
        }

        // ── 10. 최종 금액 계산 ─────────────────────────────────────
        double adjusted = baseCost
                * ageGenderFactor
                * regionFactor
                * hospitalTypeFactor
                * insuranceFactor
                * INFLATION_FACTOR;

        int minCost = (int)(adjusted * CONFIDENCE_MIN);
        int maxCost = (int)(adjusted * CONFIDENCE_MAX + 0.9999);

        log.debug("의료비 예측: base={}, ageGender={}, region={}, hospType={}, insurance={}, inflation={} → {}~{}",
                baseCost, ageGenderFactor, regionFactor, hospitalTypeFactor,
                insuranceFactor, INFLATION_FACTOR, minCost, maxCost);

        // ── 11. 결과 저장 ──────────────────────────────────────────
        User user = (userId != null)
                ? userRepository.findById(userId).orElse(null)
                : null;

        CostPrediction saved = costPredictionRepository.save(
                CostPrediction.builder()
                        .user(user)
                        .icd10Code(req.getIcd10Code())
                        .department(req.getDepartmentName())
                        .riskLevel(req.getRiskLevel())
                        .visitType(visitType)
                        .minCost(minCost)
                        .maxCost(maxCost)
                        .build()
        );

        return CostPredictResponse.builder()
                .predictionId(saved.getPredictionId())
                .icd10Code(req.getIcd10Code())
                .visitType(visitType)
                .minCost(minCost)
                .maxCost(maxCost)
                .currency("KRW")
                .build();
    }

    // ── private 헬퍼 ───────────────────────────────────────────────

    /** riskLevel 1~2 → 외래, 3~5 → 입원 */
    private String resolveVisitType(int riskLevel) {
        return riskLevel <= 2 ? "outpatient" : "inpatient";
    }

    /**
     * cost_reference 조회.
     * icd10Code → 정확 매칭 우선, 2차 시도로 상위 코드 prefix 매칭(e.g. J06.9 -> J06), 실패 시 departmentName fallback.
     */
    private CostReference resolveCostReference(CostPredictRequest req, String visitType) {
        if (req.getIcd10Code() != null && !req.getIcd10Code().isBlank()) {
            // 1차: 정확 매칭 (J06.9)
            var found = costReferenceRepository
                    .findByIcd10CodeAndVisitType(req.getIcd10Code(), visitType);
            if (found.isPresent()) return found.get();

            // ✅ 2차: 상위 코드 prefix 매칭 (J06.9 → J06)
            String prefix = req.getIcd10Code().contains(".")
                    ? req.getIcd10Code().substring(0, req.getIcd10Code().indexOf('.'))
                    : null;
            if (prefix != null) {
                var prefixFound = costReferenceRepository
                        .findByIcd10CodeAndVisitType(prefix, visitType);
                if (prefixFound.isPresent()) {
                    log.debug("cost_reference prefix 매칭: {}→{}", req.getIcd10Code(), prefix);
                    return prefixFound.get();
                }
            }

            log.debug("cost_reference ICD-10 미매칭, departmentName fallback 시도");
        }

        // 3차: departmentName fallback
        if (req.getDepartmentName() != null && !req.getDepartmentName().isBlank()) {
            var list = costReferenceRepository
                    .findByDiseaseNameContainingAndVisitType(req.getDepartmentName(), visitType);
            if (!list.isEmpty()) return list.get(0);
        }

        throw new AuthException(
                "COST_REFERENCE_NOT_FOUND",
                "해당 증상에 대한 의료비 데이터를 찾을 수 없습니다.",
                HttpStatus.BAD_REQUEST);
    }

    /**
     * 보험 여부 결정.
     * 로그인 사용자: DB 프로필(UserProfileDto.insured) 우선.
     * 게스트 또는 파라미터 없음: 요청값 사용, 미전달 시 false.
     */
    private boolean resolveInsured(CostPredictRequest req, UserProfileDto profile) {
        if (!profile.isGuest()) {
            return profile.isInsured();
        }
        return req.getHasHealthInsurance() != null && req.getHasHealthInsurance();
    }

    /**
     * 연령·성별 보정계수 결정.
     * 로그인 사용자: DB 프로필 우선.
     * 게스트: 요청 파라미터 사용.
     * age/gender 어느 쪽이든 없으면 1.0 적용.
     */
    private double resolveAgeGenderFactor(CostPredictRequest req, UserProfileDto profile) {
        int age;
        String gender;

        if (!profile.isGuest()) {
            age    = profile.getAge();
            gender = profile.getGender();
        } else {
            age    = req.getAge()    != null ? req.getAge()    : 0;
            gender = req.getGender() != null ? req.getGender() : null;
        }

        if (age <= 0 || gender == null || gender.isBlank()) {
            log.debug("연령·성별 정보 없음 → 보정계수 1.0 적용");
            return 1.0;
        }

        return costAdjustmentRepository.findFirstByAgeAndGender(age, gender)
                .map(CostAdjustment::getAdjFactorFull)
                .orElseGet(() -> {
                    log.debug("cost_adjustment 미매칭 (age={}, gender={}) → 1.0 적용", age, gender);
                    return 1.0;
                });
    }

    /**
     * 병원 종별 보정계수 결정.
     * hospitalType(clCd) 미전달 또는 미매칭 시 1.0 적용.
     */
    private double resolveHospitalTypeFactor(String hospitalType) {
        if (hospitalType == null || hospitalType.isBlank()) {
            return 1.0;
        }
        return hospitalTypeAdjustmentRepository.findByClCd(hospitalType)
                .map(ht -> ht.getAdjFactor())
                .orElseGet(() -> {
                    log.debug("hospital_type_adjustment 미매칭 (clCd={}) → 1.0 적용", hospitalType);
                    return 1.0;
                });
    }

    /**
     * 지역 보정계수 결정.
     *
     * <p>매칭 우선순위:
     * <ol>
     *   <li>region + department 정확 매칭</li>
     *   <li>region 단독 매칭 (department 미전달 또는 1차 미매칭 시)</li>
     *   <li>모두 실패 → 1.0</li>
     * </ol>
     *
     * <p>region_adjustment 테이블이 비어있는 경우(맵 API 데이터 적재 전)에도
     * Optional.empty() 처리되어 1.0 fallback이 자동 적용된다.
     *
     * @param sidoCdNm   HIRA 응답 시도명 (예: "서울", "부산")
     * @param department 진료과명 (한국어)
     */
    private double resolveRegionFactor(String sidoCdNm, String department) {
        if (sidoCdNm == null || sidoCdNm.isBlank()) {
            return 1.0;
        }

        if (department != null && !department.isBlank()) {
            var matched = regionAdjustmentRepository
                    .findByRegionAndDepartment(sidoCdNm, department);
            if (matched.isPresent()) {
                return matched.get().getAdjFactor();
            }
        }

        return regionAdjustmentRepository.findByRegion(sidoCdNm)
                .map(ra -> ra.getAdjFactor())
                .orElseGet(() -> {
                    log.debug("region_adjustment 미매칭 (region={}, dept={}) → 1.0 적용",
                            sidoCdNm, department);
                    return 1.0;
                });
    }
}