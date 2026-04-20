package com.smu.healyx.cost;

import com.smu.healyx.cost.domain.CostReference;
import com.smu.healyx.cost.repository.CostReferenceRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("local")
public class CostReferenceRepositoryTest {

    @Autowired
    private CostReferenceRepository costReferenceRepository;

    @Test
    void ICD10코드_및_방문유형으로_조회() {
        costReferenceRepository.save(CostReference.builder()
                .icd10Code("R51")
                .diseaseName("두통")
                .visitType("outpatient")
                .insuranceAvgCost(15000)
                .noInsuranceAvgCost(45000)
                .build());

        Optional<CostReference> result = costReferenceRepository
                .findByIcd10CodeAndVisitType("R51", "outpatient");

        assertThat(result).isPresent();
        assertThat(result.get().getDiseaseName()).isEqualTo("두통");
    }

    @Test
    void fallback_진료과_데이터_조회() {
        costReferenceRepository.save(CostReference.builder()
                .diseaseName("내과")
                .visitType("outpatient")
                .insuranceAvgCost(12000)
                .noInsuranceAvgCost(36000)
                .build());

        List<CostReference> result = costReferenceRepository.findByIcd10CodeIsNull();
        assertThat(result).isNotEmpty();
        assertThat(result.get(0).getIcd10Code()).isNull();
    }
}