package com.smu.healyx.auth.service;

import com.smu.healyx.auth.dto.*;
import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.security.JwtProvider;
import com.smu.healyx.email.service.EmailService;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;
    private final StringRedisTemplate redisTemplate;
    private final EmailService emailService;

    private static final int MAX_LOGIN_FAIL = 5;
    private static final long REFRESH_TOKEN_TTL_DAYS = 7;

    // ───────────────────────────────────────────────────
    // 1. 회원가입
    // ───────────────────────────────────────────────────
    @Transactional
    public void register(RegisterRequest request) {
        // 아이디·이메일 중복 검사
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new AuthException("USERNAME_DUPLICATE", "이미 사용 중인 아이디입니다.", HttpStatus.CONFLICT);
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new AuthException("EMAIL_DUPLICATE", "이미 가입된 이메일입니다.", HttpStatus.CONFLICT);
        }

        // 나이 계산 (birthDate 기준)
        Integer age = null;
        if (request.getBirthDate() != null) {
            age = Period.between(request.getBirthDate(), LocalDate.now()).getYears();
        }

        User user = User.builder()
                .username(request.getUsername())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .realName(request.getRealName())
                .email(request.getEmail())
                .nickname(request.getNickname())
                .gender(request.getGender())
                .birthDate(request.getBirthDate())
                .age(age)
                .hasHealthInsurance(request.getHasHealthInsurance())
                .preferredLanguage(request.getPreferredLanguage())
                .pushEnabled(true)
                .loginFailedCount(0)
                .isActive(true)
                .build();

        userRepository.save(user);
        log.info("회원가입 완료: username={}", request.getUsername());
    }

    // ───────────────────────────────────────────────────
    // 2. 로그인
    // ───────────────────────────────────────────────────
    @Transactional
    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND",
                        "아이디 또는 비밀번호가 올바르지 않습니다.", HttpStatus.UNAUTHORIZED));

        // 계정 잠금 확인
        if (user.getLockedUntil() != null && user.getLockedUntil().isAfter(LocalDateTime.now())) {
            throw new AuthException("ACCOUNT_LOCKED",
                    "로그인 시도가 5회 초과되어 30분간 잠겼습니다. 잠시 후 다시 시도해 주세요.",
                    HttpStatus.FORBIDDEN);
        }

        // 비밀번호 검증
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            user.incrementLoginFailedCount();
            if (user.getLoginFailedCount() >= MAX_LOGIN_FAIL) {
                user.lockAccount();
                log.warn("계정 잠금 처리: username={}", request.getUsername());
                throw new AuthException("ACCOUNT_LOCKED",
                        "비밀번호를 5회 잘못 입력하여 30분간 잠겼습니다.", HttpStatus.FORBIDDEN);
            }
            throw new AuthException("INVALID_PASSWORD",
                    "아이디 또는 비밀번호가 올바르지 않습니다.", HttpStatus.UNAUTHORIZED);
        }

        // 로그인 성공: 실패 카운트 초기화
        user.resetLoginFailed();

        // JWT 발급 및 Refresh Token Redis 저장
        String accessToken = jwtProvider.generateAccessToken(user.getUserId());
        String refreshToken = jwtProvider.generateRefreshToken(user.getUserId());
        saveRefreshToken(user.getUserId(), refreshToken);

        return LoginResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getUserId())
                .username(user.getUsername())
                .nickname(user.getNickname())
                .name(user.getRealName())
                .email(user.getEmail())
                .insuranceStatus(user.isHasHealthInsurance())
                .pushEnabled(user.isPushEnabled())
                .language(user.getPreferredLanguage())
                .build();
    }

    // ───────────────────────────────────────────────────
    // 3. Access Token 재발급
    // ───────────────────────────────────────────────────
    public TokenRefreshResponse refresh(TokenRefreshRequest request) {
        String refreshToken = request.getRefreshToken();

        if (!jwtProvider.validateToken(refreshToken)) {
            throw new AuthException("INVALID_REFRESH_TOKEN",
                    "유효하지 않은 Refresh Token입니다.", HttpStatus.UNAUTHORIZED);
        }

        Long userId = jwtProvider.getUserId(refreshToken);
        String redisKey = buildRefreshTokenKey(userId);
        String storedToken = redisTemplate.opsForValue().get(redisKey);

        if (!refreshToken.equals(storedToken)) {
            throw new AuthException("REFRESH_TOKEN_MISMATCH",
                    "Refresh Token이 일치하지 않습니다. 다시 로그인해 주세요.", HttpStatus.UNAUTHORIZED);
        }

        return new TokenRefreshResponse(jwtProvider.generateAccessToken(userId));
    }

    // ───────────────────────────────────────────────────
    // 4. 로그아웃
    // ───────────────────────────────────────────────────
    public void logout(Long userId) {
        redisTemplate.delete(buildRefreshTokenKey(userId));
        log.info("로그아웃: userId={}", userId);
    }

    // ───────────────────────────────────────────────────
    // 5. 아이디 찾기
    // ───────────────────────────────────────────────────
    public FindIdResponse findId(FindIdRequest request) {
        // 이메일 인증번호 검증 및 소비
        emailService.verifyCode(request.getEmail(), "find-id", request.getVerificationCode());

        // 실명 + 이메일로 사용자 조회
        User user = userRepository.findByRealNameAndEmail(request.getName(), request.getEmail())
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND",
                        "입력하신 정보와 일치하는 계정이 없습니다.", HttpStatus.NOT_FOUND));

        return new FindIdResponse(maskUsername(user.getUsername()));
    }

    // ───────────────────────────────────────────────────
    // 6-1. 비밀번호 재설정 검증 (1단계 — 이메일 인증번호 확인)
    // ───────────────────────────────────────────────────
    public void verifyResetPassword(VerifyResetPasswordRequest request) {
        // 이메일 인증번호 검증 및 소비
        emailService.verifyCode(request.getEmail(), "reset-pw", request.getVerificationCode());

        // 아이디 + 이메일 조합이 실제 계정인지 확인
        userRepository.findByUsernameAndEmail(request.getUsername(), request.getEmail())
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND",
                        "아이디 또는 이메일 정보가 올바르지 않습니다.", HttpStatus.NOT_FOUND));

        // 검증 완료 마커를 Redis에 저장 (TTL 5분) — 2단계에서 확인 후 소비
        redisTemplate.opsForValue().set(
                buildPasswordResetVerifiedKey(request.getUsername()),
                "true",
                5, TimeUnit.MINUTES
        );
        log.debug("비밀번호 재설정 1단계 검증 완료: username={}", request.getUsername());
    }

    // ───────────────────────────────────────────────────
    // 6-2. 비밀번호 재설정 (2단계 — 1단계 검증 완료 후)
    // ───────────────────────────────────────────────────
    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        // 1단계 검증 완료 여부 확인 (Redis 마커 소비)
        String verifiedKey = buildPasswordResetVerifiedKey(request.getUsername());
        if (!"true".equals(redisTemplate.opsForValue().get(verifiedKey))) {
            throw new AuthException("PASSWORD_RESET_NOT_VERIFIED",
                    "이메일 인증이 완료되지 않았습니다. 먼저 이메일 인증을 진행해 주세요.",
                    HttpStatus.FORBIDDEN);
        }
        redisTemplate.delete(verifiedKey);

        // 새 비밀번호 확인 일치 검증
        if (!request.getNewPassword().equals(request.getConfirmNewPassword())) {
            throw new AuthException("PASSWORD_MISMATCH",
                    "새 비밀번호와 비밀번호 확인이 일치하지 않습니다.", HttpStatus.BAD_REQUEST);
        }

        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND",
                        "사용자를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        user.updatePassword(passwordEncoder.encode(request.getNewPassword()));

        // 모든 기기의 Refresh Token 삭제
        redisTemplate.delete(buildRefreshTokenKey(user.getUserId()));
        log.info("비밀번호 재설정 완료: username={}", request.getUsername());
    }

    // ───────────────────────────────────────────────────
    // 7-1. 현재 비밀번호 검증 (1단계)
    // ───────────────────────────────────────────────────
    public void verifyCurrentPassword(Long userId, VerifyCurrentPasswordRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND",
                        "사용자를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new AuthException("INVALID_PASSWORD",
                    "현재 비밀번호가 올바르지 않습니다.", HttpStatus.BAD_REQUEST);
        }

        // 검증 완료 마커를 Redis에 저장 (TTL 5분) — 2단계에서 확인 후 소비
        redisTemplate.opsForValue().set(
                buildPasswordChangeVerifiedKey(userId),
                "true",
                5, TimeUnit.MINUTES
        );
        log.debug("현재 비밀번호 검증 완료: userId={}", userId);
    }

    // ───────────────────────────────────────────────────
    // 7-2. 비밀번호 변경 (2단계 — 1단계 검증 완료 후)
    // ───────────────────────────────────────────────────
    @Transactional
    public void changePassword(Long userId, ChangePasswordRequest request) {
        // 1단계 검증 완료 여부 확인 (Redis 마커 소비)
        String verifiedKey = buildPasswordChangeVerifiedKey(userId);
        if (!"true".equals(redisTemplate.opsForValue().get(verifiedKey))) {
            throw new AuthException("PASSWORD_CHANGE_NOT_VERIFIED",
                    "현재 비밀번호 인증이 완료되지 않았습니다. 먼저 현재 비밀번호를 확인해 주세요.",
                    HttpStatus.FORBIDDEN);
        }
        redisTemplate.delete(verifiedKey);

        // 새 비밀번호 확인 일치 검증
        if (!request.getNewPassword().equals(request.getConfirmNewPassword())) {
            throw new AuthException("PASSWORD_MISMATCH",
                    "새 비밀번호와 비밀번호 확인이 일치하지 않습니다.", HttpStatus.BAD_REQUEST);
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND",
                        "사용자를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        user.updatePassword(passwordEncoder.encode(request.getNewPassword()));

        // 모든 기기의 Refresh Token 삭제
        redisTemplate.delete(buildRefreshTokenKey(userId));
        log.info("비밀번호 변경 완료: userId={}", userId);
    }

    // ───────────────────────────────────────────────────
    // 8. 이메일 중복 확인
    // ───────────────────────────────────────────────────

    /** 이메일 중복 확인 — true: 사용 가능, false: 이미 사용 중 */
    public boolean checkEmailDuplicate(String email) {
        return !userRepository.existsByEmail(email);
    }

    /** 아이디 중복 확인 — true: 사용 가능, false: 이미 사용 중 */
    public boolean checkUsernameDuplicate(String username) {
        return !userRepository.existsByUsername(username);
    }

    // ───────────────────────────────────────────────────
    // private 헬퍼
    // ───────────────────────────────────────────────────

    /** Refresh Token을 Redis에 저장 (TTL 7일) */
    private void saveRefreshToken(Long userId, String refreshToken) {
        redisTemplate.opsForValue().set(
                buildRefreshTokenKey(userId),
                refreshToken,
                REFRESH_TOKEN_TTL_DAYS,
                TimeUnit.DAYS
        );
    }

    private String buildRefreshTokenKey(Long userId) {
        return "user:" + userId + ":refresh_token";
    }

    private String buildPasswordChangeVerifiedKey(Long userId) {
        return "password:change:verified:" + userId;
    }

    private String buildPasswordResetVerifiedKey(String username) {
        return "password:reset:verified:" + username;
    }

    /** 아이디 마스킹: 앞 4자리 표시, 나머지 * */
    private String maskUsername(String username) {
        if (username.length() <= 4) {
            return username;
        }
        return username.substring(0, 4) + "*".repeat(username.length() - 4);
    }
}
