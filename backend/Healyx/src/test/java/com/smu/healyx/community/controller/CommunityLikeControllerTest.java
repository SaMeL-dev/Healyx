package com.smu.healyx.community.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.config.SecurityConfig;
import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.security.JwtProvider;
import com.smu.healyx.community.dto.ToggleLikeResponse;
import com.smu.healyx.community.service.CommunityLikeService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * CommunityLikeController 통합 테스트 (PR-3).
 *
 * <p>전략: @WebMvcTest + SecurityConfig import + JwtProvider MockBean
 * - JwtProvider MockBean stub → JwtAuthenticationFilter 실제 동작, JWT 파싱만 대체
 * - CommunityLikeService MockBean → DB 없이 좋아요 토글 분기 검증
 */
@WebMvcTest(CommunityLikeController.class)
@Import(SecurityConfig.class)
class CommunityLikeControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private CommunityLikeService communityLikeService;

    @MockBean
    private JwtProvider jwtProvider;

    private static final String TOKEN_USER1 = "token-user1";
    private static final Long USER_ID_1 = 1L;

    @BeforeEach
    void setUpJwtMock() {
        // user1 토큰 — 유효
        given(jwtProvider.validateToken(TOKEN_USER1)).willReturn(true);
        given(jwtProvider.getUserId(TOKEN_USER1)).willReturn(USER_ID_1);

        // 그 외 토큰 — 무효
        given(jwtProvider.validateToken(argThat(t -> t != null && !t.equals(TOKEN_USER1))))
                .willReturn(false);
    }

    // ─────────────────────────────────────────────────────────────────────
    // A. 좋아요 토글 POST /api/community/posts/{postId}/likes
    // ─────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("A1: JWT 있음 + 첫 좋아요 → 200 OK, liked=true, likeCount=1")
    void toggleLike_firstLike_returns200LikedTrue() throws Exception {
        // given
        given(communityLikeService.toggleLike(USER_ID_1, 1L))
                .willReturn(new ToggleLikeResponse(true, 1));

        // when & then
        mockMvc.perform(post("/api/community/posts/1/likes")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.liked").value(true))
                .andExpect(jsonPath("$.data.likeCount").value(1));
    }

    @Test
    @DisplayName("A2: JWT 있음 + 이미 좋아요(취소) → 200 OK, liked=false, likeCount=0")
    void toggleLike_cancelLike_returns200LikedFalse() throws Exception {
        // given
        given(communityLikeService.toggleLike(USER_ID_1, 1L))
                .willReturn(new ToggleLikeResponse(false, 0));

        // when & then
        mockMvc.perform(post("/api/community/posts/1/likes")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.liked").value(false))
                .andExpect(jsonPath("$.data.likeCount").value(0));
    }

    @Test
    @DisplayName("A3: JWT 없음(비로그인) → 401 Unauthorized")
    void toggleLike_noJwt_returns401() throws Exception {
        mockMvc.perform(post("/api/community/posts/1/likes"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("A4: 존재하지 않는 postId → 404 Not Found, POST_NOT_FOUND")
    void toggleLike_postNotFound_returns404() throws Exception {
        // given
        given(communityLikeService.toggleLike(USER_ID_1, 99999L))
                .willThrow(new AuthException("POST_NOT_FOUND",
                        "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        // when & then
        mockMvc.perform(post("/api/community/posts/99999/likes")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("POST_NOT_FOUND"));
    }
}
