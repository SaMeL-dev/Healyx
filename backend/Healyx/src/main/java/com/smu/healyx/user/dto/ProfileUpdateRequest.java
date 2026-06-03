package com.smu.healyx.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class ProfileUpdateRequest {

    @NotBlank(message = "실명은 필수입니다.")
    @Size(max = 50, message = "실명은 50자 이하여야 합니다.")
    @Pattern(regexp = "^[가-힣a-zA-Z ]+$", message = "이름에는 숫자나 특수문자를 포함할 수 없습니다.")
    private String realName;

    @NotBlank(message = "이메일은 필수입니다.")
    @Email(message = "유효한 이메일 형식이 아닙니다.")
    @Size(max = 100, message = "이메일은 100자 이하여야 합니다.")
    private String email;

    @NotBlank(message = "닉네임은 필수입니다.")
    @Size(max = 50, message = "닉네임은 50자 이하여야 합니다.")
    private String nickname;

    // 허용값: "insured" (가입) / "uninsured" (미가입)
    @NotNull(message = "insuranceStatus는 필수입니다.")
    @Pattern(
        regexp = "^(insured|uninsured)$",
        message = "유효하지 않은 값입니다. 허용값: insured, uninsured"
    )
    private String insuranceStatus;
}
