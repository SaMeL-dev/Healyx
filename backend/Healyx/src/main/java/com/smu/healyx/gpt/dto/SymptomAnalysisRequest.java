package com.smu.healyx.gpt.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

/** 증상 분석 요청 DTO */
@Getter
@NoArgsConstructor
public class SymptomAnalysisRequest {

    /** 증상 텍스트 (8개 언어 모두 허용) */
    @NotBlank(message = "증상을 입력해 주세요.")
    private String symptom;
}