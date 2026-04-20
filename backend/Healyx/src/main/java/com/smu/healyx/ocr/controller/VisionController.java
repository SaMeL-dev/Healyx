package com.smu.healyx.ocr.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.ocr.dto.OcrRequest;
import com.smu.healyx.ocr.dto.OcrResponse;
import com.smu.healyx.ocr.service.VisionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Google Vision OCR 엔드포인트 — 게스트 허용 */
@RestController
@RequestMapping("/api/vision")
@RequiredArgsConstructor
public class VisionController {

    private final VisionService visionService;

    /**
     * 이미지에서 텍스트를 추출합니다.
     * POST /api/vision/ocr
     */
    @PostMapping("/ocr")
    public ResponseEntity<ApiResponse<OcrResponse>> extractText(
            @Valid @RequestBody OcrRequest request) {

        String text = visionService.extractText(request.getImageBase64());

        return ResponseEntity.ok(ApiResponse.success(
                OcrResponse.builder().extractedText(text).build()
        ));
    }
}