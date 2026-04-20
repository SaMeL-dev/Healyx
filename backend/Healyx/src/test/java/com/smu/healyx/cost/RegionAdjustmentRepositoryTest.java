package com.smu.healyx.cost;

import com.smu.healyx.cost.domain.RegionAdjustment;
import com.smu.healyx.cost.repository.RegionAdjustmentRepository;
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
public class RegionAdjustmentRepositoryTest {

    @Autowired
    private RegionAdjustmentRepository regionAdjustmentRepository;

    @Test
    void 지역_보정계수_저장_및_조회() {
        regionAdjustmentRepository.save(RegionAdjustment.builder()
                .region("서울")
                .adjFactor(1.2)
                .build());

        Optional<RegionAdjustment> result = regionAdjustmentRepository.findByRegion("서울");

        assertThat(result).isPresent();
        assertThat(result.get().getAdjFactor()).isEqualTo(1.2);
    }
}
