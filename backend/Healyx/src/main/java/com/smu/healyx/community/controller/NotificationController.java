package com.smu.healyx.community.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.community.domain.Notification;
import com.smu.healyx.community.dto.NotificationResponse;
import com.smu.healyx.community.repository.NotificationRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Notification", description = "알림 API")
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationRepository notificationRepository;

    /** 알림 목록 조회 (최신순, 페이징) */
    @Operation(summary = "알림 목록 조회", description = "로그인 사용자의 알림을 최신순으로 조회합니다.")
    @GetMapping
    public ResponseEntity<ApiResponse<Page<NotificationResponse>>> getNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        Page<NotificationResponse> result = notificationRepository
                .findByUser_UserIdOrderByCreatedAtDesc(
                        userId, PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt")))
                .map(NotificationResponse::from);
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    /** 알림 읽음 처리 */
    @Operation(summary = "알림 읽음 처리", description = "특정 알림을 읽음 상태로 변경합니다.")
    @PatchMapping("/{notificationId}/read")
    public ResponseEntity<Void> markAsRead(
            @PathVariable Long notificationId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new AuthException("NOTIFICATION_NOT_FOUND",
                        "알림을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));
        if (!notification.getUser().getUserId().equals(userId)) {
            throw new AuthException("FORBIDDEN", "해당 알림에 접근할 권한이 없습니다.", HttpStatus.FORBIDDEN);
        }
        notification.markAsRead();
        notificationRepository.save(notification);
        return ResponseEntity.noContent().build();
    }
}
