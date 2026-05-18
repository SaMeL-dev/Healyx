package com.smu.healyx.community.service;

import com.smu.healyx.community.domain.Notification;
import com.smu.healyx.community.repository.NotificationRepository;
import com.smu.healyx.fcm.service.FcmService;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final FcmService fcmService;

    /**
     * 인앱 알림 저장 + FCM 푸시 발송.
     * FCM 발송 실패 시에도 알림 저장은 보장.
     */
    @Transactional
    public void sendPushNotification(Long receiverId, String type, Long referenceId, Long postId) {
        User receiver = userRepository.findById(receiverId).orElse(null);
        if (receiver == null) {
            log.warn("알림 수신자 미존재: userId={}", receiverId);
            return;
        }

        notificationRepository.save(Notification.builder()
                .user(receiver)
                .type(type)
                .referenceId(referenceId)
                .postId(postId)
                .isRead(false)
                .build());

        try {
            fcmService.sendToUser(receiver, buildTitle(type), buildBody(type));
        } catch (Exception e) {
            log.warn("FCM 발송 실패 (알림은 저장됨): userId={}, type={}, reason={}",
                    receiverId, type, e.getMessage());
        }
    }

    private String buildTitle(String type) {
        return switch (type) {
            case "LIKE"    -> "좋아요를 받았습니다";
            case "COMMENT" -> "새 댓글이 달렸습니다";
            case "REPLY"   -> "새 대댓글이 달렸습니다";
            default        -> "새 알림이 있습니다";
        };
    }

    private String buildBody(String type) {
        return switch (type) {
            case "LIKE"    -> "회원님의 게시글에 좋아요가 추가되었습니다.";
            case "COMMENT" -> "회원님의 게시글에 새 댓글이 등록되었습니다.";
            case "REPLY"   -> "회원님의 댓글에 대댓글이 등록되었습니다.";
            default        -> "";
        };
    }
}
