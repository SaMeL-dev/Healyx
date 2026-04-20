package com.smu.healyx.email.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class EmailVerifyRequest {

    @NotBlank(message = "이메일을 입력해 주세요.")
    @Email(message = "이메일 형식이 올바르지 않습니다.")
    private String email;

    @NotBlank(message = "인증 목적을 입력해 주세요.")
    @Pattern(regexp = "^(register|find-id|reset-pw)$", message = "지원하지 않는 인증 목적입니다.")
    private String purpose;

    @NotBlank(message = "인증 코드를 입력해 주세요.")
    @Pattern(regexp = "^\\d{6}$", message = "인증 코드는 6자리 숫자입니다.")
    private String code;
}