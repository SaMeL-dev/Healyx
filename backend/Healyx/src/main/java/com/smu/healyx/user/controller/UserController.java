package com.smu.healyx.user.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.user.dto.LanguageUpdateRequest;
import com.smu.healyx.user.dto.PushSettingRequest;
import com.smu.healyx.user.dto.MyProfileResponse;
import com.smu.healyx.user.dto.ProfileUpdateRequest;
import com.smu.healyx.user.service.UserProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@Tag(name = "User", description = "사용자 프로필 API")
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserProfileService userProfileService;

    /** 내 프로필 조회 — 자동 로그인 및 프로필 화면에서 호출 */
    @Operation(summary = "내 프로필 조회")
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<MyProfileResponse>> getMyProfile(
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(userProfileService.getMyProfile(userId)));
    }

    /** 선호 언어 변경 — 로그인 사용자 전용, 게스트는 SharedPreferences에만 저장 */
    @Operation(summary = "선호 언어 변경", description = "지원 언어: ko, zh, vi, th, en, ja")
    @PatchMapping("/me/language")
    public ResponseEntity<ApiResponse<Void>> updateLanguage(
            @Valid @RequestBody LanguageUpdateRequest request,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        userProfileService.updateLanguage(userId, request.getLanguageCode());
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /** 프로필 일괄 수정 — 실명·이메일·닉네임·건강보험 가입 상태를 한 번에 변경 */
    @Operation(summary = "프로필 수정", description = "실명, 이메일, 닉네임, 건강보험 가입 상태를 한 번에 변경합니다.")
    @PatchMapping("/me/profile")
    public ResponseEntity<ApiResponse<Void>> updateProfile(
            @Valid @RequestBody ProfileUpdateRequest request,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        userProfileService.updateProfile(userId, request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /** 알림 설정 변경 */
    @Operation(summary = "알림 설정 변경", description = "푸시 알림을 켜거나 끕니다.")
    @PatchMapping("/me/push")
    public ResponseEntity<ApiResponse<Void>> updatePushSetting(
            @Valid @RequestBody PushSettingRequest request,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        userProfileService.updatePushSetting(userId, request.getPushEnabled());
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /** 회원 탈퇴 — 소프트 삭제 */
    @Operation(summary = "회원 탈퇴", description = "계정을 즉시 비활성화합니다.")
    @DeleteMapping("/me")
    public ResponseEntity<ApiResponse<Void>> withdraw(Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        userProfileService.withdraw(userId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
