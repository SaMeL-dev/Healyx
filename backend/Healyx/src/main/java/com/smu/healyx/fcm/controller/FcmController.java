package com.smu.healyx.fcm.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.fcm.dto.FcmSendRequest;
import com.smu.healyx.fcm.service.FcmService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Tag(name = "FCM", description = "푸시 알림 테스트 API")
@RestController
@RequestMapping("/api/fcm")
@RequiredArgsConstructor
public class FcmController {

    private final FcmService fcmService;

    /**
     * FCM 토큰으로 푸시 알림을 직접 발송합니다. (Swagger 테스트 전용)
     */
    @Operation(summary = "푸시 알림 테스트 발송", description = "FCM 토큰, 제목, 내용을 입력하면 해당 기기로 푸시 알림을 발송합니다.")
    @PostMapping("/test")
    public ResponseEntity<ApiResponse<String>> testSend(
            @Valid @RequestBody FcmSendRequest request) {

        fcmService.send(request.getFcmToken(), request.getTitle(), request.getBody());
        return ResponseEntity.ok(ApiResponse.success("푸시 알림이 발송되었습니다."));
    }
}