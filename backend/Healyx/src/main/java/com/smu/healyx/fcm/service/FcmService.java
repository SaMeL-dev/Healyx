package com.smu.healyx.fcm.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.smu.healyx.common.exception.ExternalApiException;
import com.smu.healyx.user.domain.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class FcmService {

    private final FirebaseMessaging firebaseMessaging;

    /**
     * 단건 푸시 알림을 발송합니다.
     * pushEnabled=false인 사용자는 발송을 건너뜁니다.
     */
    public void sendToUser(User user, String title, String body) {
        if (!user.isPushEnabled()) {
            log.debug("푸시 알림 OFF 사용자 건너뜀: userId={}", user.getUserId());
            return;
        }

        if (user.getFcmToken() == null || user.getFcmToken().isBlank()) {
            log.debug("FCM 토큰 없음: userId={}", user.getUserId());
            return;
        }

        send(user.getFcmToken(), title, body);
    }

    /**
     * FCM 토큰을 직접 지정하여 단건 발송합니다. (테스트·내부 호출용)
     */
    public void send(String fcmToken, String title, String body) {
        Message message = Message.builder()
                .setNotification(Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build())
                .setToken(fcmToken)
                .build();

        try {
            String messageId = firebaseMessaging.send(message);
            log.debug("FCM 발송 성공: messageId={}", messageId);
        } catch (FirebaseMessagingException e) {
            log.error("FCM 발송 실패: code={}, message={}", e.getMessagingErrorCode(), e.getMessage());
            throw new ExternalApiException("FCM_SEND_FAILED", "푸시 알림 발송에 실패했습니다.");
        }
    }

    /**
     * 여러 사용자에게 동일한 알림을 발송합니다.
     * 개별 실패가 전체 발송을 중단하지 않도록 예외를 로그로만 처리합니다.
     */
    public void sendToUsers(List<User> users, String title, String body) {
        for (User user : users) {
            try {
                sendToUser(user, title, body);
            } catch (ExternalApiException e) {
                log.warn("다건 발송 중 일부 실패: userId={}, reason={}", user.getUserId(), e.getMessage());
            }
        }
    }
}