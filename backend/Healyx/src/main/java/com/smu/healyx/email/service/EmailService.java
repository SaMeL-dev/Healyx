package com.smu.healyx.email.service;

import com.smu.healyx.common.exception.ExternalApiException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.internet.MimeMessage;
import java.security.SecureRandom;
import java.time.Duration;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;
    private final StringRedisTemplate redisTemplate;

    @Value("${spring.mail.username}")
    private String senderEmail;

    // 인증 코드 TTL: 3분
    private static final Duration CODE_TTL = Duration.ofMinutes(3);
    private static final int CODE_LENGTH = 6;

    /**
     * 이메일로 6자리 인증 코드를 발송하고 Redis에 저장합니다.
     * Redis 키: email:verify:{purpose}:{email}
     */
    public void sendVerificationCode(String email, String purpose) {
        String code = generateCode();
        String redisKey = buildRedisKey(purpose, email);

        // Redis에 코드 저장 (TTL 3분)
        redisTemplate.opsForValue().set(redisKey, code, CODE_TTL);

        // 이메일 발송
        sendEmail(email, purpose, code);
        log.debug("인증 코드 발송 완료: purpose={}, email={}****", purpose, email.substring(0, 4));
    }

    /**
     * 입력된 코드가 Redis에 저장된 코드와 일치하는지 검증합니다.
     * 검증 성공 시 Redis에서 코드를 즉시 삭제합니다.
     */
    public void verifyCode(String email, String purpose, String inputCode) {
        String redisKey = buildRedisKey(purpose, email);
        String savedCode = redisTemplate.opsForValue().get(redisKey);

        if (savedCode == null) {
            throw new ExternalApiException("EMAIL_CODE_EXPIRED", "인증 코드가 만료되었거나 존재하지 않습니다. 다시 요청해 주세요.");
        }

        if (!savedCode.equals(inputCode)) {
            throw new ExternalApiException("EMAIL_CODE_INVALID", "인증 코드가 올바르지 않습니다.");
        }

        // 검증 성공 후 즉시 삭제 (재사용 방지)
        redisTemplate.delete(redisKey);
        log.debug("인증 코드 검증 성공: purpose={}, email={}****", purpose, email.substring(0, 4));
    }

    /** 6자리 숫자 인증 코드를 생성합니다. */
    private String generateCode() {
        SecureRandom random = new SecureRandom();
        int code = 100000 + random.nextInt(900000);
        return String.valueOf(code);
    }

    /** Redis 키를 생성합니다. */
    private String buildRedisKey(String purpose, String email) {
        return "email:verify:" + purpose + ":" + email;
    }

    /** HTML 형식의 인증 코드 이메일을 발송합니다. */
    private void sendEmail(String to, String purpose, String code) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(senderEmail);
            helper.setTo(to);
            helper.setSubject(buildSubject(purpose));
            helper.setText(buildEmailBody(purpose, code), true);

            mailSender.send(message);

        } catch (Exception e) {
            log.error("이메일 발송 실패: {}", e.getMessage());
            throw new ExternalApiException("EMAIL_SEND_FAILED", "이메일 발송에 실패했습니다. 잠시 후 다시 시도해 주세요.");
        }
    }

    /** 인증 목적에 따른 이메일 제목을 반환합니다. */
    private String buildSubject(String purpose) {
        return switch (purpose) {
            case "register"  -> "[HEALYX] 회원가입 이메일 인증 코드";
            case "find-id"   -> "[HEALYX] 아이디 찾기 인증 코드";
            case "reset-pw"  -> "[HEALYX] 비밀번호 재설정 인증 코드";
            default          -> "[HEALYX] 이메일 인증 코드";
        };
    }

    /** 인증 코드를 포함한 HTML 이메일 본문을 반환합니다. */
    private String buildEmailBody(String purpose, String code) {
        String purposeText = switch (purpose) {
            case "register" -> "회원가입";
            case "find-id"  -> "아이디 찾기";
            case "reset-pw" -> "비밀번호 재설정";
            default         -> "이메일 인증";
        };

        return """
                <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; border: 1px solid #e0e0e0; border-radius: 8px;">
                    <h2 style="color: #2563eb; margin-bottom: 8px;">HEALYX</h2>
                    <p style="color: #374151; font-size: 15px;">%s을(를) 위한 이메일 인증 코드입니다.</p>
                    <div style="background: #f3f4f6; border-radius: 8px; padding: 20px; text-align: center; margin: 24px 0;">
                        <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #1d4ed8;">%s</span>
                    </div>
                    <p style="color: #6b7280; font-size: 13px;">이 코드는 <b>3분</b> 후 만료됩니다.</p>
                    <p style="color: #6b7280; font-size: 13px;">본인이 요청하지 않은 경우 이 메일을 무시하세요.</p>
                </div>
                """.formatted(purposeText, code);
    }
}