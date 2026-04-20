package com.smu.healyx.email.service;

import com.smu.healyx.common.exception.ExternalApiException;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EmailServiceTest {

    @Mock
    private JavaMailSender mailSender;

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @InjectMocks
    private EmailService emailService;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(emailService, "senderEmail", "test@gmail.com");
        given(redisTemplate.opsForValue()).willReturn(valueOperations);
    }

    // ───────────────────────────────────────────────
    // sendVerificationCode 테스트
    // ───────────────────────────────────────────────

    @Test
    @DisplayName("회원가입 인증 코드 발송 시 Redis에 올바른 키로 저장된다")
    void sendVerificationCode_register_savesCorrectRedisKey() {
        // given
        MimeMessage mimeMessage = mock(MimeMessage.class);
        given(mailSender.createMimeMessage()).willReturn(mimeMessage);

        // when
        emailService.sendVerificationCode("user@example.com", "register");

        // then — Redis 키 패턴: email:verify:{purpose}:{email}
        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> valueCaptor = ArgumentCaptor.forClass(String.class);
        verify(valueOperations).set(keyCaptor.capture(), valueCaptor.capture(), eq(Duration.ofMinutes(3)));

        assertThat(keyCaptor.getValue()).isEqualTo("email:verify:register:user@example.com");
        assertThat(valueCaptor.getValue()).matches("\\d{6}");  // 6자리 숫자
    }

    @Test
    @DisplayName("비밀번호 재설정 인증 코드 발송 시 Redis에 올바른 키로 저장된다")
    void sendVerificationCode_resetPw_savesCorrectRedisKey() {
        // given
        MimeMessage mimeMessage = mock(MimeMessage.class);
        given(mailSender.createMimeMessage()).willReturn(mimeMessage);

        // when
        emailService.sendVerificationCode("user@example.com", "reset-pw");

        // then
        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        verify(valueOperations).set(keyCaptor.capture(), any(), eq(Duration.ofMinutes(3)));

        assertThat(keyCaptor.getValue()).isEqualTo("email:verify:reset-pw:user@example.com");
    }

    @Test
    @DisplayName("이메일 발송 실패 시 EMAIL_SEND_FAILED 예외가 발생한다")
    void sendVerificationCode_mailSendFails_throwsException() {
        // given — createMimeMessage()가 예외를 던지도록 설정
        given(mailSender.createMimeMessage()).willThrow(new RuntimeException("SMTP connection failed"));

        // when & then
        assertThatThrownBy(() -> emailService.sendVerificationCode("user@example.com", "register"))
                .isInstanceOf(ExternalApiException.class)
                .hasMessageContaining("이메일 발송에 실패");
    }

    // ───────────────────────────────────────────────
    // verifyCode 테스트
    // ───────────────────────────────────────────────

    @Test
    @DisplayName("올바른 코드 입력 시 검증에 성공하고 Redis 키가 삭제된다")
    void verifyCode_correctCode_success() {
        // given
        String email = "user@example.com";
        String purpose = "register";
        String redisKey = "email:verify:register:user@example.com";
        given(valueOperations.get(redisKey)).willReturn("482910");

        // when
        emailService.verifyCode(email, purpose, "482910");

        // then — 검증 성공 후 키 삭제 확인
        verify(redisTemplate).delete(redisKey);
    }

    @Test
    @DisplayName("Redis에 코드가 없으면 EMAIL_CODE_EXPIRED 예외가 발생한다")
    void verifyCode_codeExpired_throwsException() {
        // given — Redis에 키 없음 (null 반환)
        given(valueOperations.get(anyString())).willReturn(null);

        // when & then
        assertThatThrownBy(() -> emailService.verifyCode("user@example.com", "register", "482910"))
                .isInstanceOf(ExternalApiException.class)
                .hasMessageContaining("만료");
    }

    @Test
    @DisplayName("코드가 일치하지 않으면 EMAIL_CODE_INVALID 예외가 발생한다")
    void verifyCode_wrongCode_throwsException() {
        // given
        given(valueOperations.get(anyString())).willReturn("482910");

        // when & then
        assertThatThrownBy(() -> emailService.verifyCode("user@example.com", "register", "000000"))
                .isInstanceOf(ExternalApiException.class)
                .hasMessageContaining("올바르지 않습니다");
    }

    @Test
    @DisplayName("검증 실패 시 Redis 키가 삭제되지 않는다")
    void verifyCode_wrongCode_doesNotDeleteRedisKey() {
        // given
        given(valueOperations.get(anyString())).willReturn("482910");

        // when
        try {
            emailService.verifyCode("user@example.com", "register", "000000");
        } catch (ExternalApiException ignored) {}

        // then — 잘못된 코드 입력 시 키 유지 (재시도 가능)
        verify(redisTemplate, never()).delete(anyString());
    }

    @Test
    @DisplayName("아이디 찾기 인증 코드 검증 성공 시 Redis 키가 삭제된다")
    void verifyCode_findId_success() {
        // given
        String redisKey = "email:verify:find-id:user@example.com";
        given(valueOperations.get(redisKey)).willReturn("123456");

        // when
        emailService.verifyCode("user@example.com", "find-id", "123456");

        // then
        verify(redisTemplate).delete(redisKey);
    }
}
