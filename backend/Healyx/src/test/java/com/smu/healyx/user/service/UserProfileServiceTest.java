package com.smu.healyx.user.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.dto.MyProfileResponse;
import com.smu.healyx.user.repository.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;

import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.given;

@ExtendWith(MockitoExtension.class)
class UserProfileServiceTest {

    @Mock private UserRepository userRepository;

    @InjectMocks
    private UserProfileService userProfileService;

    // ─────────────────────────────────────────────
    // 공통 헬퍼
    // ─────────────────────────────────────────────

    private User buildUser(boolean insured) {
        return User.builder()
                .userId(1L)
                .username("testuser")
                .passwordHash("$2a$10$hashedPassword")
                .realName("홍길동")
                .email("test@example.com")
                .nickname("테스터")
                .gender("M")
                .birthDate(LocalDate.of(1995, 6, 15))
                .age(29)
                .hasHealthInsurance(insured)
                .preferredLanguage("ko")
                .pushEnabled(true)
                .loginFailedCount(0)
                .isActive(true)
                .build();
    }

    // ─────────────────────────────────────────────
    // 1. 내 프로필 조회
    // ─────────────────────────────────────────────

    @Nested
    @DisplayName("내 프로필 조회")
    class GetMyProfile {

        @Test
        @DisplayName("존재하는 사용자 조회 시 모든 프로필 필드가 반환된다")
        void getMyProfile_success_returnsAllFields() {
            User user = buildUser(true);
            given(userRepository.findById(1L)).willReturn(Optional.of(user));

            MyProfileResponse res = userProfileService.getMyProfile(1L);

            assertThat(res.getUserId()).isEqualTo(1L);
            assertThat(res.getNickname()).isEqualTo("테스터");
            assertThat(res.getName()).isEqualTo("홍길동");
            assertThat(res.getEmail()).isEqualTo("test@example.com");
            assertThat(res.getGender()).isEqualTo("M");
            assertThat(res.getAge()).isEqualTo(29);
            assertThat(res.isInsuranceStatus()).isTrue();
            assertThat(res.getPreferredLanguage()).isEqualTo("ko");
        }

        @Test
        @DisplayName("존재하지 않는 userId 조회 시 예외가 발생한다")
        void getMyProfile_userNotFound_throwsException() {
            given(userRepository.findById(999L)).willReturn(Optional.empty());

            assertThatThrownBy(() -> userProfileService.getMyProfile(999L))
                    .isInstanceOf(Exception.class);
        }
    }

    // ─────────────────────────────────────────────
    // 2. 선호 언어 변경
    // ─────────────────────────────────────────────

    @Nested
    @DisplayName("선호 언어 변경")
    class UpdateLanguage {

        @Test
        @DisplayName("언어 코드 변경 시 사용자의 preferredLanguage가 업데이트된다")
        void updateLanguage_success_updatesField() {
            User user = buildUser(true); // preferredLanguage = "ko"
            given(userRepository.findById(1L)).willReturn(Optional.of(user));

            userProfileService.updateLanguage(1L, "en");

            assertThat(user.getPreferredLanguage()).isEqualTo("en");
        }

        @Test
        @DisplayName("존재하지 않는 userId이면 USER_NOT_FOUND(404) 예외가 발생한다")
        void updateLanguage_userNotFound_throwsNotFound() {
            given(userRepository.findById(999L)).willReturn(Optional.empty());

            assertThatThrownBy(() -> userProfileService.updateLanguage(999L, "en"))
                    .isInstanceOf(AuthException.class)
                    .satisfies(e -> {
                        AuthException ae = (AuthException) e;
                        assertThat(ae.getErrorCode()).isEqualTo("USER_NOT_FOUND");
                        assertThat(ae.getStatus()).isEqualTo(HttpStatus.NOT_FOUND);
                    });
        }
    }

}
