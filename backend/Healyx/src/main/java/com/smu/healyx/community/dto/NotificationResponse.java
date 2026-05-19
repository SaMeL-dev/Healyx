package com.smu.healyx.community.dto;

import com.smu.healyx.community.domain.Notification;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class NotificationResponse {

    private Long notificationId;
    private String type;
    private Long referenceId;
    private Long postId;
    private boolean isRead;
    private LocalDateTime createdAt;

    public static NotificationResponse from(Notification n) {
        return NotificationResponse.builder()
                .notificationId(n.getNotificationId())
                .type(n.getType())
                .referenceId(n.getReferenceId())
                .postId(n.getPostId())
                .isRead(n.isRead())
                .createdAt(n.getCreatedAt())
                .build();
    }
}
