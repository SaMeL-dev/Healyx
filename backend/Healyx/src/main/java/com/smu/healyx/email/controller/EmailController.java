package com.smu.healyx.email.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.email.dto.EmailSendRequest;
import com.smu.healyx.email.dto.EmailVerifyRequest;
import com.smu.healyx.email.service.EmailService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 이메일 인증 엔드포인트 — 인증 불필요 (permitAll) */
@RestController
@RequestMapping("/api/email")
@RequiredArgsConstructor
public class EmailController {

    private final EmailService emailService;

    /**
     * 인증 코드를 이메일로 발송합니다.
     * POST /api/email/send
     */
    @PostMapping("/send")
    public ResponseEntity<ApiResponse<Void>> sendVerificationCode(
            @Valid @RequestBody EmailSendRequest request) {

        emailService.sendVerificationCode(request.getEmail(), request.getPurpose());

        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /**
     * 인증 코드를 검증합니다.
     * POST /api/email/verify
     */
    @PostMapping("/verify")
    public ResponseEntity<ApiResponse<Void>> verifyCode(
            @Valid @RequestBody EmailVerifyRequest request) {

        emailService.verifyCode(request.getEmail(), request.getPurpose(), request.getCode());

        return ResponseEntity.ok(ApiResponse.success(null));
    }
}