package com.smu.healyx.cost.repository;

import com.smu.healyx.cost.domain.CostReference;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface CostReferenceRepository extends JpaRepository<CostReference, Long> {
    Optional<CostReference> findByIcd10CodeAndVisitType(String icd10Code, String visitType);
    List<CostReference> findByDiseaseNameContainingAndVisitType(String diseaseName, String visitType);
    List<CostReference> findByIcd10CodeIsNull();
}