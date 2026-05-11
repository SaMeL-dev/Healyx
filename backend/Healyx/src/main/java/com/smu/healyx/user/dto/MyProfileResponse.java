package com.smu.healyx.user.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

/** 자동 로그인 및 프로필 조회용 응답 DTO */
@Getter
@Builder
public class MyProfileResponse {

    private Long userId;
    private String realName;
    private String nickname;
    private String name;
    private String email;
    private String gender;
    private LocalDate birthDate;
    private Integer age;
    private boolean insuranceStatus;
    private String preferredLanguage;
    private boolean pushEnabled;
}
