package com.smu.healyx.cost.repository;

import com.smu.healyx.cost.domain.RegionAdjustment;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface RegionAdjustmentRepository extends JpaRepository<RegionAdjustment, Long> {
    Optional<RegionAdjustment> findByRegion(String region);
}
