package com.smu.healyx.common.validation;

import com.smu.healyx.auth.dto.RegisterRequest;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class PasswordMatchValidator implements ConstraintValidator<PasswordMatch, RegisterRequest> {

    @Override
    public boolean isValid(RegisterRequest request, ConstraintValidatorContext context) {
        if (request.getPassword() == null || request.getPasswordConfirm() == null) {
            return true; // null 체크는 @NotBlank에서 처리
        }

        boolean matches = request.getPassword().equals(request.getPasswordConfirm());

        if (!matches) {
            // 필드 에러로 등록하여 GlobalExceptionHandler의 fieldErrors에서 처리
            context.disableDefaultConstraintViolation();
            context.buildConstraintViolationWithTemplate(context.getDefaultConstraintMessageTemplate())
                   .addPropertyNode("passwordConfirm")
                   .addConstraintViolation();
        }

        return matches;
    }
}