package com.smu.healyx.hospital.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.hospital.dto.BodyIconResponse;
import com.smu.healyx.hospital.dto.HospitalRecommendRequest;
import com.smu.healyx.hospital.dto.HospitalRecommendResponse;
import com.smu.healyx.hospital.service.HospitalRecommendService;
import com.smu.healyx.user.dto.UserProfileDto;
import com.smu.healyx.user.service.UserProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Hospital", description = "병원 찾기 API")
@RestController
@RequestMapping("/api/hospitals")
@RequiredArgsConstructor
public class HospitalRecommendController {

    private final HospitalRecommendService hospitalRecommendService;
    private final UserProfileService userProfileService;

    @Operation(
            summary = "병원 추천",
            description = "AI Agent가 증상·위험도를 분석하여 HIRA API 기반으로 병원 추천. 게스트/로그인 모두 허용."
    )
    @PostMapping("/recommend")
    public ResponseEntity<ApiResponse<HospitalRecommendResponse>> recommend(
            @Valid @RequestBody HospitalRecommendRequest request,
            Authentication authentication) {

        UserProfileDto userProfile = resolveUserProfile(authentication);
        return ResponseEntity.ok(ApiResponse.success(
                hospitalRecommendService.recommend(request, userProfile)));
    }

    // ── 신체 아이콘 → 증상 키워드 (HX_H_002, UI-HOS-05) — 게스트 허용 ──
    // 인터페이스 설계서 IF-006 / 요구사항 HOS-003: STT는 Flutter SDK 직접 호출(PM 확정).
    // 본 컨트롤러는 STT 백엔드 엔드포인트를 보유하지 않는다.

    @Operation(
            summary = "신체 아이콘 키워드 조회",
            description = "Flutter UI에서 신체 부위 아이콘을 선택하면 해당 부위의 증상 키워드 목록을 반환. " +
                    "다중 선택 시 N회 호출 후 클라이언트에서 합성하여 추천 API symptom으로 전달."
    )
    @GetMapping("/body-icons/{iconId}/keywords")
    public ResponseEntity<ApiResponse<BodyIconResponse>> getBodyIconKeywords(
            @PathVariable String iconId) {
        return ResponseEntity.ok(ApiResponse.success(
                hospitalRecommendService.mapBodyIconToKeyword(iconId)));
    }

    /**
     * 인증 여부에 따라 사용자 프로필 결정.
     * 로그인: JWT → userId → DB 조회 (나이·성별·보험 → 의료비 보정 적용)
     * 게스트: 기본값 (ICD-10 코드만으로 의료비 계산)
     */
    private UserProfileDto resolveUserProfile(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()
                || authentication instanceof AnonymousAuthenticationToken) {
            return UserProfileDto.guestDefault();
        }
        Long userId = SecurityUtils.extractUserId(authentication);
        return userProfileService.getProfile(userId);
    }
}