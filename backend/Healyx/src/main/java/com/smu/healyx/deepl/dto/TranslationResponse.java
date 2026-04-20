package com.smu.healyx.deepl.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TranslationResponse {

    private String translatedText;

    // DeepL이 감지한 원문 언어 코드 (예: "KO")
    private String detectedSourceLanguage;

    // 실제 사용된 대상 언어 코드 (예: "EN-US")
    private String targetLanguage;
}