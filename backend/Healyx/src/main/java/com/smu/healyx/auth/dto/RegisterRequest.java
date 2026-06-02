package com.smu.healyx.auth.dto;

import com.smu.healyx.common.validation.PasswordMatch;
import jakarta.validation.constraints.*;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@PasswordMatch
public class RegisterRequest {

    @NotBlank
    @Size(max = 50)
    @Pattern(regexp = "^[가-힣a-zA-Z ]+$", message = "이름에는 숫자나 특수문자를 포함할 수 없습니다.")
    private String realName;

    @NotBlank
    @Email
    private String email;

    // 아이디
    @NotBlank
    @Size(min = 4, max = 30)
    private String username;

    // 영문 + 숫자 + 특수기호 조합, 7~12자
    @NotBlank
    @Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]).{7,12}$",
             message = "비밀번호는 영문, 숫자, 특수기호를 포함한 7~12자여야 합니다.")
    private String password;

    @NotBlank(message = "비밀번호 확인은 필수입니다.")
    private String passwordConfirm;

    @NotBlank
    @Size(max = 10)
    private String nickname;

    @NotNull(message = "생년월일은 필수입니다.")
    private LocalDate birthDate;

    @NotNull(message = "성별은 필수입니다.")
    @Pattern(regexp = "^[MF]$", message = "성별은 M 또는 F여야 합니다.")
    private String gender;

    @NotNull(message = "건강보험 가입 여부는 필수입니다.")
    private Boolean hasHealthInsurance;

    @NotBlank
    private String preferredLanguage;
}
