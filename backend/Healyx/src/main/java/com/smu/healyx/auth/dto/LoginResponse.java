package com.smu.healyx.auth.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class LoginResponse {
    private String accessToken;
    private String refreshToken;
    private Long userId;
    private String username;
    private String nickname;
    private String name;
    private String email;
    private boolean insuranceStatus;
    private boolean pushEnabled;
    private String language;
}
