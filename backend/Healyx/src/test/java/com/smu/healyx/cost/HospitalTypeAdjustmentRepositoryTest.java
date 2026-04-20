package com.smu.healyx.cost;

import com.smu.healyx.cost.domain.HospitalTypeAdjustment;
import com.smu.healyx.cost.repository.HospitalTypeAdjustmentRepository;
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
public class HospitalTypeAdjustmentRepositoryTest {

    @Autowired
    private HospitalTypeAdjustmentRepository hospitalTypeAdjustmentRepository;

    @Test
    void 병원유형_보정계수_저장_및_조회() {
        hospitalTypeAdjustmentRepository.save(HospitalTypeAdjustment.builder()
                .hospitalType("상급종합병원")
                .adjFactor(1.5)
                .build());

        Optional<HospitalTypeAdjustment> result = hospitalTypeAdjustmentRepository
                .findByHospitalType("상급종합병원");

        assertThat(result).isPresent();
        assertThat(result.get().getAdjFactor()).isEqualTo(1.5);
    }
}
