package com.smu.healyx.deepl.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.deepl.dto.TranslationRequest;
import com.smu.healyx.deepl.dto.TranslationResponse;
import com.smu.healyx.deepl.service.TranslationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** DeepL 번역 엔드포인트 — 게스트 허용 */
@RestController
@RequestMapping("/api/translation")
@RequiredArgsConstructor
public class TranslationController {

    private final TranslationService translationService;

    /**
     * 텍스트를 지정한 언어로 번역합니다.
     * POST /api/translation/translate
     */
    @PostMapping("/translate")
    public ResponseEntity<ApiResponse<TranslationResponse>> translate(
            @Valid @RequestBody TranslationRequest request) {

        TranslationResponse response = translationService.translate(
                request.getText(),
                request.getTargetLanguage()
        );

        return ResponseEntity.ok(ApiResponse.success(response));
    }
}