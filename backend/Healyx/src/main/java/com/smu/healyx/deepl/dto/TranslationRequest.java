package com.smu.healyx.deepl.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class TranslationRequest {

    @NotBlank(message = "번역할 텍스트를 입력해 주세요.")
    private String text;

    // DeepL 지원 언어: ko, zh, vi, th, en, ja
    @NotBlank(message = "대상 언어를 입력해 주세요.")
    @Pattern(regexp = "^(ko|zh|vi|th|en|ja)$", message = "지원하지 않는 언어 코드입니다.")
    private String targetLanguage;
}