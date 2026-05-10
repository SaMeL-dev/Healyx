package com.smu.healyx.user.domain;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "username", nullable = false, unique = true, length = 30)
    private String username;

    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Column(name = "real_name", nullable = false, length = 50)
    private String realName;

    @Column(name = "email", nullable = false, unique = true, length = 100)
    private String email;

    @Column(name = "nickname", nullable = false, length = 50)
    private String nickname;

    @Column(name = "gender", length = 1)
    private String gender;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "age")
    private Integer age;

    @Column(name = "has_health_insurance", nullable = false,
            columnDefinition = "TINYINT(1) DEFAULT 0")
    private boolean hasHealthInsurance;

    @Column(name = "preferred_language", nullable = false, length = 10)
    private String preferredLanguage;

    @Column(name = "push_enabled", nullable = false,
            columnDefinition = "TINYINT(1) DEFAULT 1")
    private boolean pushEnabled;

    @Column(name = "fcm_token", length = 255)
    private String fcmToken;

    @Column(name = "login_failed_count", nullable = false)
    private int loginFailedCount;

    @Column(name = "locked_until")
    private LocalDateTime lockedUntil;

    @Column(name = "is_active", nullable = false,
            columnDefinition = "TINYINT(1) DEFAULT 1")
    private boolean isActive;

    /** 비밀번호 변경 */
    public void updatePassword(String newPasswordHash) {
        this.passwordHash = newPasswordHash;
    }

    /** 로그인 실패 횟수 증가 */
    public void incrementLoginFailedCount() {
        this.loginFailedCount++;
    }

    /** 로그인 성공 시 실패 카운트 및 잠금 초기화 */
    public void resetLoginFailed() {
        this.loginFailedCount = 0;
        this.lockedUntil = null;
    }

    /** 로그인 5회 실패 시 30분 잠금 */
    public void lockAccount() {
        this.lockedUntil = LocalDateTime.now().plusMinutes(30);
    }

    /** 만 나이 갱신 */
    public void updateAge(int age) {
        this.age = age;
    }

    /** 선호 언어 변경 */
    public void updateLanguage(String languageCode) {
        this.preferredLanguage = languageCode;
    }

    /** 알림 설정 변경 */
    public void updatePushSetting(boolean pushEnabled) {
        this.pushEnabled = pushEnabled;
    }

    /** 프로필 일괄 수정 (실명·이메일·닉네임·건강보험 가입 상태) */
    public void updateProfile(String realName, String email, String nickname, boolean insured) {
        this.realName = realName;
        this.email = email;
        this.nickname = nickname;
        this.hasHealthInsurance = insured;
    }
}