package com.smu.healyx.community;

import com.smu.healyx.community.domain.Notification;
import com.smu.healyx.community.repository.NotificationRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("local")
public class NotificationRepositoryTest {

    @Autowired private NotificationRepository notificationRepository;
    @Autowired private UserRepository userRepository;

    @Test
    void 알림_저장_및_미읽음_조회() {
        User user = userRepository.save(User.builder()
                .username("notiuser1").passwordHash("hash")
                .realName("알림유저").email("noti@healyx.com")
                .nickname("알림닉").preferredLanguage("en")
                .build());

        notificationRepository.save(Notification.builder()
                .user(user).type("COMMENT")
                .message("새 댓글이 달렸습니다")
                .build());

        notificationRepository.save(Notification.builder()
                .user(user).type("LIKE")
                .message("좋아요를 받았습니다")
                .isRead(true)
                .build());

        List<Notification> unread = notificationRepository
                .findByUser_UserIdAndIsReadFalse(user.getUserId());

        assertThat(unread).hasSize(1);
        assertThat(unread.get(0).getType()).isEqualTo("COMMENT");
    }
}
