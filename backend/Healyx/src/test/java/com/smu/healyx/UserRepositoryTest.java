package com.smu.healyx;

import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("local")
public class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @Test
    void 유저_저장_및_조회() {
        User user = User.builder()
                .username("testuser1")
                .passwordHash("hashedpw123")
                .realName("Test User")
                .email("test@healyx.com")
                .nickname("테스터")
                .preferredLanguage("en")
                .hasHealthInsurance(false)
                .pushEnabled(true)
                .loginFailedCount(0)
                .isActive(true)
                .build();

        userRepository.save(user);

        Optional<User> found = userRepository.findByUsername("testuser1");
        assertThat(found).isPresent();
        assertThat(found.get().getEmail()).isEqualTo("test@healyx.com");
    }

    @Test
    void 이메일_중복_확인() {
        User user = User.builder()
                .username("testuser2")
                .passwordHash("hashedpw123")
                .realName("Test User2")
                .email("test2@healyx.com")
                .nickname("테스터2")
                .preferredLanguage("en")
                .hasHealthInsurance(false)
                .pushEnabled(true)
                .loginFailedCount(0)
                .isActive(true)
                .build();

        userRepository.save(user);

        assertThat(userRepository.existsByEmail("test2@healyx.com")).isTrue();
        assertThat(userRepository.existsByEmail("none@healyx.com")).isFalse();
    }
}