package com.smu.healyx.auth.controller;

import com.smu.healyx.auth.dto.*;
import com.smu.healyx.auth.service.AuthService;
import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Auth", description = "회원 인증 API")
@Validated
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /** 이메일 중복 확인 — true: 사용 가능, false: 이미 사용 중 */
    @Operation(summary = "이메일 중복 확인")
    @GetMapping("/check-email")
    public ResponseEntity<ApiResponse<Boolean>> checkEmail(
            @RequestParam @NotBlank @Email String email) {
        boolean available = authService.checkEmailDuplicate(email);
        return ResponseEntity.ok(ApiResponse.success(available));
    }

    /** 아이디 중복 확인 — true: 사용 가능, false: 이미 사용 중 */
    @Operation(summary = "아이디 중복 확인")
    @GetMapping("/check-username")
    public ResponseEntity<ApiResponse<Boolean>> checkUsername(
            @RequestParam @NotBlank String username) {
        boolean available = authService.checkUsernameDuplicate(username);
        return ResponseEntity.ok(ApiResponse.success(available));
    }

    /** 회원가입 — 이메일 인증 완료 후 호출 */
    @Operation(summary = "회원가입")
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<Void>> register(
            @Valid @RequestBody RegisterRequest request) {
        authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(null));
    }

    /** 로그인 → Access Token + Refresh Token 발급 */
    @Operation(summary = "로그인")
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(
            @Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(ApiResponse.success(authService.login(request)));
    }

    /** Access Token 재발급 (Refresh Token 검증) */
    @Operation(summary = "Access Token 재발급")
    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<TokenRefreshResponse>> refresh(
            @Valid @RequestBody TokenRefreshRequest request) {
        return ResponseEntity.ok(ApiResponse.success(authService.refresh(request)));
    }

    /** 로그아웃 — Redis의 Refresh Token 삭제 */
    @Operation(summary = "로그아웃")
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(Authentication authentication) {
        authService.logout(SecurityUtils.extractUserId(authentication));
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /** 아이디 찾기 — 이메일 인증 완료 후 호출 */
    @Operation(summary = "아이디 찾기")
    @PostMapping("/find-id")
    public ResponseEntity<ApiResponse<FindIdResponse>> findId(
            @Valid @RequestBody FindIdRequest request) {
        return ResponseEntity.ok(ApiResponse.success(authService.findId(request)));
    }

    /** 비밀번호 재설정 1단계 — 아이디 + 이메일 인증번호 검증 (Redis에 완료 마커 저장) */
    @Operation(summary = "비밀번호 재설정 이메일 검증 (1단계)")
    @PostMapping("/verify-reset-password")
    public ResponseEntity<ApiResponse<Void>> verifyResetPassword(
            @Valid @RequestBody VerifyResetPasswordRequest request) {
        authService.verifyResetPassword(request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /** 비밀번호 재설정 2단계 — 1단계 검증 완료 후 새 비밀번호로 변경 */
    @Operation(summary = "비밀번호 재설정 (2단계)")
    @PutMapping("/reset-password")
    public ResponseEntity<ApiResponse<Void>> resetPassword(
            @Valid @RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /** 비밀번호 변경 1단계 — 현재 비밀번호 검증 (Redis에 완료 마커 저장) */
    @Operation(summary = "현재 비밀번호 검증 (비밀번호 변경 1단계)")
    @PostMapping("/verify-current-password")
    public ResponseEntity<ApiResponse<Void>> verifyCurrentPassword(
            Authentication authentication,
            @Valid @RequestBody VerifyCurrentPasswordRequest request) {
        authService.verifyCurrentPassword(SecurityUtils.extractUserId(authentication), request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /** 비밀번호 변경 2단계 — 1단계 검증 완료 후 새 비밀번호로 변경 */
    @Operation(summary = "비밀번호 변경 (비밀번호 변경 2단계)")
    @PutMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            Authentication authentication,
            @Valid @RequestBody ChangePasswordRequest request) {
        authService.changePassword(SecurityUtils.extractUserId(authentication), request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
