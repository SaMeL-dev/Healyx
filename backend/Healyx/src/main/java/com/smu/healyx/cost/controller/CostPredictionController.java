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
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Cost", description = "의료비 예측 API")
@RestController
@RequestMapping("/api/cost")
@RequiredArgsConstructor
public class CostPredictionController {

    private final CostPredictionService costPredictionService;
    private final UserProfileService    userProfileService;

    @Operation(
            summary = "의료비 예측",
            description = "ICD-10 코드 또는 진료과명 기반으로 연령·성별·종별 보정 후 ±25% 신뢰구간 예상 비용 반환. 로그인만 허용."
    )
    @PostMapping("/predict")
    public ResponseEntity<ApiResponse<CostPredictResponse>> predict(
            @Valid @RequestBody CostPredictRequest request,
            Authentication authentication) {

        Long userId = SecurityUtils.extractUserId(authentication);
        UserProfileDto userProfile = userProfileService.getProfile(userId);

        return ResponseEntity.ok(ApiResponse.success(
                costPredictionService.predict(request, userProfile, userId)));
    }
}