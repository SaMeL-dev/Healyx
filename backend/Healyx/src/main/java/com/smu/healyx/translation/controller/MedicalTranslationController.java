package com.smu.healyx.translation.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.translation.dto.MedicalTranslationRequest;
import com.smu.healyx.translation.dto.MedicalTranslationResponse;
import com.smu.healyx.translation.service.MedicalTranslationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/translations")
@RequiredArgsConstructor
public class MedicalTranslationController {

    private final MedicalTranslationService medicalTranslationService;

    /**
     * 의료 문서 이미지 번역 (오버레이 방식).
     * 게스트: 번역 결과를 Base64로 반환, DB 저장 없음.
     * 로그인 사용자: S3 업로드 + 번역 보관함(medical_translations)에 저장.
     */
    @PostMapping("/medical")
    public ResponseEntity<ApiResponse<MedicalTranslationResponse>> translate(
            @RequestBody @Valid MedicalTranslationRequest request,
            Authentication authentication) {

        Long userId = resolveUserId(authentication);
        MedicalTranslationResponse response = medicalTranslationService.translate(request, userId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    /** 비로그인(게스트)이면 null 반환 */
    private Long resolveUserId(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()
                || authentication instanceof AnonymousAuthenticationToken) {
            return null;
        }
        return SecurityUtils.extractUserId(authentication);
    }
}
