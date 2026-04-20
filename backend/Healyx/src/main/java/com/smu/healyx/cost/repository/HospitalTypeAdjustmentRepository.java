package com.smu.healyx.cost.repository;

import com.smu.healyx.cost.domain.HospitalTypeAdjustment;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface HospitalTypeAdjustmentRepository extends JpaRepository<HospitalTypeAdjustment, Long> {
    Optional<HospitalTypeAdjustment> findByHospitalType(String hospitalType);
}
