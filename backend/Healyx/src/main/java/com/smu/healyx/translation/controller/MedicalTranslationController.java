package com.smu.healyx.translation.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.translation.dto.MedicalTranslationRequest;
import com.smu.healyx.translation.dto.MedicalTranslationResponse;
import com.smu.healyx.translation.dto.TranslationArchiveItem;
import com.smu.healyx.translation.service.MedicalTranslationService;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

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

    /** 번역 보관함 조회 — JWT 필요, 최신순 반환 */
    @Operation(summary = "번역 보관함 조회", description = "로그인 사용자의 번역 내역을 최신순으로 반환합니다.")
    @GetMapping("/archive")
    public ResponseEntity<ApiResponse<List<TranslationArchiveItem>>> getArchive(
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(medicalTranslationService.getArchive(userId)));
    }

    /** 번역 보관함 항목 개별 조회 — JWT 필요, 본인 항목만 조회 가능 */
    @Operation(summary = "번역 보관함 항목 개별 조회", description = "본인의 번역 항목 하나를 조회합니다.")
    @GetMapping("/archive/{translationId}")
    public ResponseEntity<ApiResponse<TranslationArchiveItem>> getArchiveItem(
            @PathVariable Long translationId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(medicalTranslationService.getArchiveItem(userId, translationId)));
    }

    /** 번역 보관함 항목 삭제 — JWT 필요, 본인 항목만 삭제 가능 */
    @Operation(summary = "번역 보관함 항목 삭제", description = "본인의 번역 항목만 삭제할 수 있습니다.")
    @DeleteMapping("/archive/{translationId}")
    public ResponseEntity<ApiResponse<Void>> deleteArchiveItem(
            @PathVariable Long translationId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        medicalTranslationService.deleteArchiveItem(userId, translationId);
        return ResponseEntity.ok(ApiResponse.success(null));
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
