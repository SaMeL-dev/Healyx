package com.smu.healyx.cost.repository;

import com.smu.healyx.cost.domain.CostPrediction;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface CostPredictionRepository extends JpaRepository<CostPrediction, Long> {
    List<CostPrediction> findByUser_UserId(Long userId);
    List<CostPrediction> findByUserIsNull();
}