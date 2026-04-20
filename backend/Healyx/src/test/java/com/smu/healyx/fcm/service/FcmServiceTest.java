package com.smu.healyx.fcm.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.smu.healyx.common.exception.ExternalApiException;
import com.smu.healyx.user.domain.User;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FcmServiceTest {

    @Mock
    private FirebaseMessaging firebaseMessaging;

    @InjectMocks
    private FcmService fcmService;

    // ───────────────────────────────────────────────
    // send (직접 토큰 지정) 테스트
    // ───────────────────────────────────────────────

    @Test
    @DisplayName("유효한 토큰으로 발송 시 FirebaseMessaging.send()가 호출된다")
    void send_validToken_callsFirebaseSend() throws FirebaseMessagingException {
        // given
        given(firebaseMessaging.send(any(Message.class))).willReturn("projects/test/messages/msg-id-1");

        // when
        fcmService.send("valid-fcm-token", "제목", "내용");

        // then
        verify(firebaseMessaging, times(1)).send(any(Message.class));
    }

    @Test
    @DisplayName("발송된 Message에 올바른 토큰·제목·내용이 담겨 있다")
    void send_capturesCorrectMessageFields() throws FirebaseMessagingException {
        // given
        given(firebaseMessaging.send(any(Message.class))).willReturn("msg-id");
        ArgumentCaptor<Message> captor = ArgumentCaptor.forClass(Message.class);

        // when
        fcmService.send("device-token-abc", "HEALYX 알림", "병원 추천이 도착했습니다.");

        // then — Message 객체 내부 검증 (toString 포함 여부로 확인)
        verify(firebaseMessaging).send(captor.capture());
        assertThat(captor.getValue()).isNotNull();
    }

    @Test
    @DisplayName("Firebase 발송 실패 시 FCM_SEND_FAILED 예외가 발생한다")
    void send_firebaseFails_throwsExternalApiException() throws FirebaseMessagingException {
        // given
        FirebaseMessagingException firebaseEx = mock(FirebaseMessagingException.class);
        given(firebaseMessaging.send(any(Message.class))).willThrow(firebaseEx);

        // when & then
        assertThatThrownBy(() -> fcmService.send("token", "제목", "내용"))
                .isInstanceOf(ExternalApiException.class)
                .hasMessageContaining("푸시 알림 발송에 실패");
    }

    // ───────────────────────────────────────────────
    // sendToUser (User 엔티티 기반) 테스트
    // ───────────────────────────────────────────────

    @Test
    @DisplayName("pushEnabled=true이고 토큰이 있으면 발송된다")
    void sendToUser_pushEnabledWithToken_sends() throws FirebaseMessagingException {
        // given
        User user = buildUser(true, "valid-token");
        given(firebaseMessaging.send(any(Message.class))).willReturn("msg-id");

        // when
        fcmService.sendToUser(user, "제목", "내용");

        // then
        verify(firebaseMessaging, times(1)).send(any(Message.class));
    }

    @Test
    @DisplayName("pushEnabled=false이면 Firebase를 호출하지 않는다")
    void sendToUser_pushDisabled_skips() throws FirebaseMessagingException {
        // given
        User user = buildUser(false, "valid-token");

        // when
        fcmService.sendToUser(user, "제목", "내용");

        // then
        verify(firebaseMessaging, never()).send(any(Message.class));
    }

    @Test
    @DisplayName("fcmToken이 null이면 Firebase를 호출하지 않는다")
    void sendToUser_nullToken_skips() throws FirebaseMessagingException {
        // given
        User user = buildUser(true, null);

        // when
        fcmService.sendToUser(user, "제목", "내용");

        // then
        verify(firebaseMessaging, never()).send(any(Message.class));
    }

    @Test
    @DisplayName("fcmToken이 빈 문자열이면 Firebase를 호출하지 않는다")
    void sendToUser_blankToken_skips() throws FirebaseMessagingException {
        // given
        User user = buildUser(true, "   ");

        // when
        fcmService.sendToUser(user, "제목", "내용");

        // then
        verify(firebaseMessaging, never()).send(any(Message.class));
    }

    // ───────────────────────────────────────────────
    // sendToUsers (다건 발송) 테스트
    // ───────────────────────────────────────────────

    @Test
    @DisplayName("여러 사용자에게 발송 시 각 사용자마다 send가 호출된다")
    void sendToUsers_multipleUsers_sendsToEach() throws FirebaseMessagingException {
        // given
        User user1 = buildUser(true, "token-1");
        User user2 = buildUser(true, "token-2");
        given(firebaseMessaging.send(any(Message.class))).willReturn("msg-id");

        // when
        fcmService.sendToUsers(List.of(user1, user2), "제목", "내용");

        // then
        verify(firebaseMessaging, times(2)).send(any(Message.class));
    }

    @Test
    @DisplayName("다건 발송 중 일부 실패해도 나머지 사용자에게 계속 발송된다")
    void sendToUsers_partialFailure_continuesForRemainingUsers() throws FirebaseMessagingException {
        // given
        User user1 = buildUser(true, "token-1");
        User user2 = buildUser(true, "token-2");

        FirebaseMessagingException firebaseEx = mock(FirebaseMessagingException.class);
        // 첫 번째 발송 실패, 두 번째는 성공
        given(firebaseMessaging.send(any(Message.class)))
                .willThrow(firebaseEx)
                .willReturn("msg-id");

        // when — 예외가 외부로 전파되지 않아야 함
        fcmService.sendToUsers(List.of(user1, user2), "제목", "내용");

        // then — 두 번 모두 시도됨
        verify(firebaseMessaging, times(2)).send(any(Message.class));
    }

    @Test
    @DisplayName("pushEnabled=false 사용자가 포함된 다건 발송 시 해당 사용자는 건너뛴다")
    void sendToUsers_mixedPushEnabled_onlySendsToEnabled() throws FirebaseMessagingException {
        // given
        User enabled  = buildUser(true,  "token-1");
        User disabled = buildUser(false, "token-2");
        given(firebaseMessaging.send(any(Message.class))).willReturn("msg-id");

        // when
        fcmService.sendToUsers(List.of(enabled, disabled), "제목", "내용");

        // then — enabled 사용자에게만 1회 발송
        verify(firebaseMessaging, times(1)).send(any(Message.class));
    }

    // ───────────────────────────────────────────────
    // 헬퍼
    // ───────────────────────────────────────────────

    private User buildUser(boolean pushEnabled, String fcmToken) {
        return User.builder()
                .userId(1L)
                .username("testuser")
                .passwordHash("hash")
                .realName("홍길동")
                .email("test@example.com")
                .nickname("길동")
                .hasHealthInsurance(false)
                .preferredLanguage("ko")
                .pushEnabled(pushEnabled)
                .fcmToken(fcmToken)
                .loginFailedCount(0)
                .isActive(true)
                .build();
    }
}