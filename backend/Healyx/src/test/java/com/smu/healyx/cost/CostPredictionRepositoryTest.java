package com.smu.healyx.cost;

import com.smu.healyx.cost.domain.CostPrediction;
import com.smu.healyx.cost.repository.CostPredictionRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("local")
public class CostPredictionRepositoryTest {

    @Autowired private CostPredictionRepository costPredictionRepository;
    @Autowired private UserRepository userRepository;

    @Test
    void 로그인_사용자_예측_저장_및_조회() {
        User user = userRepository.save(User.builder()
                .username("costuser1")
                .passwordHash("hash")
                .realName("비용유저")
                .email("cost@healyx.com")
                .nickname("비용닉")
                .preferredLanguage("en")
                .build());

        costPredictionRepository.save(CostPrediction.builder()
                .user(user)
                .symptomInput("두통이 심해요")
                .icd10Code("R51")
                .riskLevel(2)
                .visitType("outpatient")
                .minCost(15000)
                .maxCost(25000)
                .build());

        List<CostPrediction> result = costPredictionRepository
                .findByUser_UserId(user.getUserId());
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getIcd10Code()).isEqualTo("R51");
    }

    @Test
    void 비로그인_사용자_예측_저장_및_조회() {
        costPredictionRepository.save(CostPrediction.builder()
                .symptomInput("배가 아파요")
                .riskLevel(1)
                .visitType("outpatient")
                .minCost(10000)
                .maxCost(20000)
                .build());

        List<CostPrediction> result = costPredictionRepository.findByUserIsNull();
        assertThat(result).isNotEmpty();
    }
}