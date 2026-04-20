package com.smu.healyx.email.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class EmailSendRequest {

    @NotBlank(message = "이메일을 입력해 주세요.")
    @Email(message = "이메일 형식이 올바르지 않습니다.")
    private String email;

    // register: 회원가입 | find-id: 아이디 찾기 | reset-pw: 비밀번호 재설정
    @NotBlank(message = "인증 목적 입력")
    @Pattern(regexp = "^(register|find-id|reset-pw)$", message = "지원하지 않는 인증 목적")
    private String purpose;
}