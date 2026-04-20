package com.smu.healyx.cost;

import com.smu.healyx.cost.domain.CostAdjustment;
import com.smu.healyx.cost.repository.CostAdjustmentRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("local")
public class CostAdjustmentRepositoryTest {

    @Autowired
    private CostAdjustmentRepository costAdjustmentRepository;

    @Test
    void 연령성별_보정계수_조회() {
        costAdjustmentRepository.save(CostAdjustment.builder()
                .ageMax(9).gender("M").adjFactor(1.2).adjFactorFull(1.5).build());

        costAdjustmentRepository.save(CostAdjustment.builder()
                .ageMax(19).gender("M").adjFactor(0.9).adjFactorFull(1.1).build());

        Optional<CostAdjustment> result = costAdjustmentRepository
                .findFirstByAgeAndGender(7, "M");

        assertThat(result).isPresent();
        assertThat(result.get().getAgeMax()).isEqualTo(9);
    }
}
