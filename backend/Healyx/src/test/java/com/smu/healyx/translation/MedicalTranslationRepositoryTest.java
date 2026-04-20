package com.smu.healyx.translation;

import com.smu.healyx.translation.domain.MedicalTranslation;
import com.smu.healyx.translation.repository.MedicalTranslationRepository;
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
public class MedicalTranslationRepositoryTest {

    @Autowired private MedicalTranslationRepository medicalTranslationRepository;
    @Autowired private UserRepository userRepository;

    @Test
    void 로그인_사용자_번역_저장_및_조회() {
        User user = userRepository.save(User.builder()
                .username("transuser1")
                .passwordHash("hash")
                .realName("번역유저")
                .email("trans@healyx.com")
                .nickname("번역닉")
                .preferredLanguage("en")
                .build());

        medicalTranslationRepository.save(MedicalTranslation.builder()
                .user(user)
                .originalText("두통이 심합니다")
                .translatedText("I have a severe headache")
                .sourceLang("ko")
                .targetLang("en")
                .build());

        List<MedicalTranslation> result = medicalTranslationRepository
                .findByUser_UserId(user.getUserId());

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getTargetLang()).isEqualTo("en");
    }

    @Test
    void 비로그인_사용자_번역_저장_및_조회() {
        medicalTranslationRepository.save(MedicalTranslation.builder()
                .originalText("열이 납니다")
                .translatedText("I have a fever")
                .sourceLang("ko")
                .targetLang("en")
                .build());

        List<MedicalTranslation> result = medicalTranslationRepository.findByUserIsNull();
        assertThat(result).isNotEmpty();
    }
}
