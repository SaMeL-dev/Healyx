package com.smu.healyx.cost.service;

import com.smu.healyx.cost.domain.CostAdjustment;
import com.smu.healyx.cost.domain.CostReference;
import com.smu.healyx.cost.domain.HospitalTypeAdjustment;
import com.smu.healyx.cost.domain.RegionAdjustment;
import com.smu.healyx.cost.repository.CostAdjustmentRepository;
import com.smu.healyx.cost.repository.CostReferenceRepository;
import com.smu.healyx.cost.repository.HospitalTypeAdjustmentRepository;
import com.smu.healyx.cost.repository.RegionAdjustmentRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

/**
 * cost 도메인 마스터 데이터 캐싱 서비스.
 *
 * <p>{@link CostPredictionService}의 resolveXxx 헬퍼들이 사용하는 Repository 호출을
 * 별도 컴포넌트로 추출하여 Caffeine {@code @Cacheable}을 적용한다.
 * Spring AOP 프록시는 self-invocation에서 동작하지 않으므로 이 분리가 필수적이다.
 *
 * <p>캐시 무효화: 마스터 데이터는 운영 중 변경 빈도 매우 낮음 (24h TTL).
 * userById는 30s TTL (user 정보 변경 반영 보장).
 */
@Service
@RequiredArgsConstructor
public class CostMasterDataService {

    private final CostReferenceRepository          costReferenceRepository;
    private final CostAdjustmentRepository         costAdjustmentRepository;
    private final HospitalTypeAdjustmentRepository hospitalTypeAdjustmentRepository;
    private final RegionAdjustmentRepository       regionAdjustmentRepository;
    private final UserRepository                   userRepository;

    /**
     * ICD-10 코드 + visitType으로 cost_reference 정확 조회.
     * 캐시 키: icd10Code + ':' + visitType
     */
    @Cacheable(value = "costReferenceByIcd", key = "#icd10Code + ':' + #visitType",
               unless = "#result == null")
    public CostReference findCostReferenceByIcd(String icd10Code, String visitType) {
        return costReferenceRepository.findByIcd10CodeAndVisitType(icd10Code, visitType)
                .orElse(null);
    }

    /**
     * 진료과명 + visitType으로 cost_reference 목록 조회 (departmentName fallback).
     * 캐시 키: departmentName + ':' + visitType
     */
    @Cacheable(value = "costReferenceByDept", key = "#departmentName + ':' + #visitType")
    public List<CostReference> findCostReferenceByDept(String departmentName, String visitType) {
        return costReferenceRepository
                .findByDiseaseNameContainingAndVisitType(departmentName, visitType);
    }

    /**
     * 연령·성별 보정계수 조회.
     * 캐시 키: age + ':' + gender
     */
    @Cacheable(value = "costAdjustment", key = "#age + ':' + #gender", unless = "#result == null")
    public CostAdjustment findCostAdjustment(int age, String gender) {
        return costAdjustmentRepository.findFirstByAgeAndGender(age, gender)
                .orElse(null);
    }

    /**
     * 시도명 + 진료과명으로 지역 보정계수 조회.
     * 캐시 키: region + ':' + department
     *
     * <p>region_adjustment 테이블이 비어있어 null 반환이 빈번하므로
     * null 결과도 캐싱한다(Spring NullValue wrapping). 미적재 데이터에
     * 대한 매 호출 DB 풀스캔을 막기 위함.
     */
    @Cacheable(value = "regionAdjustment", key = "#region + ':' + #department")
    public RegionAdjustment findRegionAdjustmentByRegionAndDept(String region, String department) {
        return regionAdjustmentRepository.findByRegionAndDepartment(region, department)
                .orElse(null);
    }

    /**
     * 시도명 단독으로 지역 보정계수 조회 (department 미전달 또는 1차 미매칭 fallback).
     * 캐시 키: region + ':' + "_"
     *
     * <p>region_adjustment 테이블 미적재로 인한 null 반환도 캐싱.
     */
    @Cacheable(value = "regionAdjustment", key = "#region + ':_'")
    public RegionAdjustment findRegionAdjustmentByRegion(String region) {
        return regionAdjustmentRepository.findByRegion(region)
                .orElse(null);
    }

    /**
     * 병원 종별 보정계수 조회.
     * 캐시 키: clCd
     */
    @Cacheable(value = "hospitalTypeAdjustment", key = "#clCd", unless = "#result == null")
    public HospitalTypeAdjustment findHospitalTypeAdjustment(String clCd) {
        return hospitalTypeAdjustmentRepository.findByClCd(clCd)
                .orElse(null);
    }

    /**
     * userId 기준 User 조회. TTL 30s (user 정보 변경 반영 보장).
     *
     * <p>게스트(userId=null)는 캐시 자체를 건너뛴다. Spring Cache는
     * key SpEL이 null로 평가되면 IllegalArgumentException을 던지므로
     * condition으로 캐시 경로를 우회한 뒤 메서드 본문이 null을 반환한다.
     */
    @Cacheable(value = "userById", key = "#userId",
               condition = "#userId != null", unless = "#result == null")
    public User findUserById(Long userId) {
        if (userId == null) return null;
        return userRepository.findById(userId).orElse(null);
    }
}
