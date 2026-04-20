package com.smu.healyx.ocr.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

/** Google Vision OCR 요청 DTO */
@Getter
@NoArgsConstructor
public class OcrRequest {

    /** Base64 인코딩된 이미지 (Flutter에서 인코딩하여 전달) */
    @NotBlank(message = "이미지 데이터를 입력해 주세요.")
    private String imageBase64;
}