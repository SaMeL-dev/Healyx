package com.smu.healyx.cost.repository;

import com.smu.healyx.cost.domain.RegionAdjustment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RegionAdjustmentRepository extends JpaRepository<RegionAdjustment, Long> {

    /** 시도명 단독 조회 (진료과 미지정 fallback). */
    Optional<RegionAdjustment> findByRegion(String region);

    /**
     * 시도명 + 진료과 복합 키 조회.
     * region_adjustment 테이블 PK가 (region, department) 복합 의미를 가지므로
     * 두 값이 모두 있을 때 정확 매칭. 미매칭 시 호출자가 1.0 fallback 처리.
     */
    Optional<RegionAdjustment> findByRegionAndDepartment(String region, String department);
}
