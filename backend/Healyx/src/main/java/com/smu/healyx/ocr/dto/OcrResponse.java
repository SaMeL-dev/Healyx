package com.smu.healyx.ocr.dto;

import lombok.Builder;
import lombok.Getter;

/** Google Vision OCR 응답 DTO */
@Getter
@Builder
public class OcrResponse {

    /** 이미지에서 추출된 전체 텍스트 */
    private String extractedText;
}