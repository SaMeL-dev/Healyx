package com.smu.healyx.community.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.config.SecurityConfig;
import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.security.JwtProvider;
import com.smu.healyx.community.domain.Notification;
import com.smu.healyx.community.dto.NotificationResponse;
import com.smu.healyx.community.repository.NotificationRepository;
import com.smu.healyx.user.domain.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * NotificationController 통합 테스트 (PR-4).
 *
 * <p>전략: @WebMvcTest + SecurityConfig import + JwtProvider MockBean
 * - NotificationController는 서비스 레이어 없이 NotificationRepository 직접 주입 구조
 * - NotificationRepository 도 @MockBean 으로 처리하여 DB 없이 HTTP 계층 검증
 */
@WebMvcTest(NotificationController.class)
@Import(SecurityConfig.class)
class NotificationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private NotificationRepository notificationRepository;

    @MockBean
    private JwtProvider jwtProvider;

    private static final String TOKEN_USER1 = "token-user1";
    private static final Long USER_ID_1 = 1L;

    /** user1 용 User 픽스처 (Notification.getUser().getUserId() 비교에 사용) */
    private User mockUser;

    /** notificationId=1, userId=USER_ID_1 인 알림 픽스처 */
    private Notification mockNotification;

    @BeforeEach
    void setUpJwtMock() {
        // user1 토큰 — 유효
        given(jwtProvider.validateToken(TOKEN_USER1)).willReturn(true);
        given(jwtProvider.getUserId(TOKEN_USER1)).willReturn(USER_ID_1);

        // 그 외 토큰 — 무효
        given(jwtProvider.validateToken(argThat(t -> t != null && !t.equals(TOKEN_USER1))))
                .willReturn(false);

        // User 픽스처 (notificationId Owner 검증용)
        mockUser = User.builder()
                .userId(USER_ID_1)
                .username("user1")
                .passwordHash("hash")
                .realName("테스트유저")
                .email("user1@test.com")
                .nickname("user1")
                .preferredLanguage("en")
                .build();

        // Notification 픽스처
        mockNotification = Notification.builder()
                .notificationId(1L)
                .user(mockUser)
                .type("LIKE")
                .referenceId(10L)
                .isRead(false)
                .createdAt(LocalDateTime.now())
                .build();
    }

    // ─────────────────────────────────────────────────────────────────────
    // N1: GET /api/notifications — 로그인 시 200 + Page 반환
    // ─────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("N1: JWT 있음 + 알림 목록 조회 → 200 OK, Page 반환")
    void getNotifications_withJwt_returns200WithPage() throws Exception {
        // given
        NotificationResponse item = NotificationResponse.from(mockNotification);
        Page<Notification> page = new PageImpl<>(List.of(mockNotification));
        given(notificationRepository.findByUser_UserIdOrderByCreatedAtDesc(
                eq(USER_ID_1), any(Pageable.class)))
                .willReturn(page);

        // when & then
        mockMvc.perform(get("/api/notifications")
                        .param("page", "0")
                        .param("size", "20")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content[0].notificationId").value(1))
                .andExpect(jsonPath("$.data.content[0].type").value("LIKE"))
                .andExpect(jsonPath("$.data.content[0].referenceId").value(10))
                .andExpect(jsonPath("$.data.content[0].read").value(false));
    }

    // ─────────────────────────────────────────────────────────────────────
    // N2: GET /api/notifications — 비로그인 시 401
    // ─────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("N2: JWT 없음(비로그인) + 알림 목록 조회 → 401 Unauthorized")
    void getNotifications_noJwt_returns401() throws Exception {
        mockMvc.perform(get("/api/notifications"))
                .andExpect(status().isUnauthorized());
    }

    // ─────────────────────────────────────────────────────────────────────
    // N3: PATCH /api/notifications/1/read — 로그인 시 204
    // ─────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("N3: JWT 있음 + 알림 읽음 처리 → 204 No Content")
    void markAsRead_withJwt_returns204() throws Exception {
        // given — notificationId=1 이 userId=USER_ID_1 소유
        given(notificationRepository.findById(1L))
                .willReturn(Optional.of(mockNotification));
        given(notificationRepository.save(mockNotification))
                .willReturn(mockNotification);

        // when & then
        mockMvc.perform(patch("/api/notifications/1/read")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isNoContent());

        // verify: markAsRead() 이후 save() 가 호출됐는지 확인
        then(notificationRepository).should().save(mockNotification);
    }

    // ─────────────────────────────────────────────────────────────────────
    // N4: PATCH /api/notifications/999/read — 없는 알림 → 404
    // ─────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("N4: JWT 있음 + 존재하지 않는 notificationId → 404 Not Found, NOTIFICATION_NOT_FOUND")
    void markAsRead_notFound_returns404() throws Exception {
        // given — notificationId=999 없음
        given(notificationRepository.findById(999L))
                .willReturn(Optional.empty());

        // when & then
        mockMvc.perform(patch("/api/notifications/999/read")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("NOTIFICATION_NOT_FOUND"));
    }

    // ─────────────────────────────────────────────────────────────────────
    // N5: PATCH /api/notifications/1/read — 비로그인 시 401
    // ─────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("N5: JWT 없음(비로그인) + 알림 읽음 처리 → 401 Unauthorized")
    void markAsRead_noJwt_returns401() throws Exception {
        mockMvc.perform(patch("/api/notifications/1/read"))
                .andExpect(status().isUnauthorized());
    }
}
