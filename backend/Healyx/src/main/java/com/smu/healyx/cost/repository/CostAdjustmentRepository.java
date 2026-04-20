package com.smu.healyx.cost.repository;

import com.smu.healyx.cost.domain.CostAdjustment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface CostAdjustmentRepository extends JpaRepository<CostAdjustment, Long> {
    @Query("SELECT c FROM CostAdjustment c WHERE c.ageMax >= :age AND c.gender = :gender ORDER BY c.ageMax ASC LIMIT 1")
    Optional<CostAdjustment> findFirstByAgeAndGender(@Param("age") int age, @Param("gender") String gender);
}
