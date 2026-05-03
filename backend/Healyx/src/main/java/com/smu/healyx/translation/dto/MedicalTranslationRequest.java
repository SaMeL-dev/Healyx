package com.smu.healyx.translation.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class MedicalTranslationRequest {

    @NotBlank(message = "이미지 데이터가 필요합니다.")
    private String imageBase64;

    @NotBlank(message = "대상 언어를 지정해 주세요.")
    private String targetLanguage;
}
