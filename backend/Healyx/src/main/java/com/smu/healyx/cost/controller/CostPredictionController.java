package com.smu.healyx.cost.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.cost.dto.CostPredictRequest;
import com.smu.healyx.cost.dto.CostPredictResponse;
import com.smu.healyx.cost.service.CostPredictionService;
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

@Tag(name = "Cost", description = "의료비 예측 API")
@RestController
@RequestMapping("/api/cost")
@RequiredArgsConstructor
public class CostPredictionController {

    private final CostPredictionService costPredictionService;
    private final UserProfileService    userProfileService;

    @Operation(
            summary = "의료비 예측",
            description = "ICD-10 코드 또는 진료과명 기반으로 연령·성별·종별 보정 후 ±25% 신뢰구간 예상 비용 반환. 게스트/로그인 모두 허용."
    )
    @PostMapping("/predict")
    public ResponseEntity<ApiResponse<CostPredictResponse>> predict(
            @Valid @RequestBody CostPredictRequest request,
            Authentication authentication) {

        Long userId = resolveUserId(authentication);
        UserProfileDto userProfile = resolveUserProfile(authentication, userId);

        return ResponseEntity.ok(ApiResponse.success(
                costPredictionService.predict(request, userProfile, userId)));
    }

    // ── private 헬퍼 ───────────────────────────────────────────────

    private Long resolveUserId(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()
                || authentication instanceof AnonymousAuthenticationToken) {
            return null;
        }
        return SecurityUtils.extractUserId(authentication);
    }

    /**
     * 인증 여부에 따라 사용자 프로필 결정.
     * 로그인: DB 프로필(나이·성별·보험) → 보정 계수 적용
     * 게스트: 요청 파라미터 또는 기본값 사용
     */
    private UserProfileDto resolveUserProfile(Authentication authentication, Long userId) {
        if (userId == null) {
            return UserProfileDto.guestDefault();
        }
        return userProfileService.getProfile(userId);
    }
}