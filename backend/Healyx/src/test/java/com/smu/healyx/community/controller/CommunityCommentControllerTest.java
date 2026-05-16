package com.smu.healyx.community.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.config.SecurityConfig;
import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.security.JwtProvider;
import com.smu.healyx.community.service.CommunityCommentService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * CommunityCommentController 통합 테스트.
 *
 * <p>전략: @WebMvcTest + SecurityConfig import + JwtProvider MockBean
 * - JwtProvider를 MockBean으로 stub → JwtAuthenticationFilter가 실제 동작하되 JWT 파싱만 대체
 * - CommunityCommentService는 MockBean → DB 없이 비즈니스 로직 분기 검증
 * - Firebase/S3/Redis 의존성은 WebMvcTest 슬라이스에서 로드되지 않으므로 별도 MockBean 불필요
 */
@WebMvcTest(CommunityCommentController.class)
@Import(SecurityConfig.class)
class CommunityCommentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private CommunityCommentService commentService;

    @MockBean
    private JwtProvider jwtProvider;

    private static final String TOKEN_USER1 = "token-user1";
    private static final String TOKEN_USER2 = "token-user2";
    private static final Long USER_ID_1 = 1L;
    private static final Long USER_ID_2 = 2L;

    @BeforeEach
    void setUpJwtMock() {
        // user1 토큰 — 유효
        given(jwtProvider.validateToken(TOKEN_USER1)).willReturn(true);
        given(jwtProvider.getUserId(TOKEN_USER1)).willReturn(USER_ID_1);

        // user2 토큰 — 유효
        given(jwtProvider.validateToken(TOKEN_USER2)).willReturn(true);
        given(jwtProvider.getUserId(TOKEN_USER2)).willReturn(USER_ID_2);

        // 그 외 토큰 — 무효
        given(jwtProvider.validateToken(argThat(t -> t != null
                && !t.equals(TOKEN_USER1)
                && !t.equals(TOKEN_USER2)))).willReturn(false);
    }

    // ─────────────────────────────────────────────────────────────
    // A. 댓글 등록 POST /api/community/posts/{postId}/comments
    // ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("A1: depth=0 댓글 정상 등록 → 201 Created, commentId=10 반환")
    void createComment_depth0_returns201() throws Exception {
        given(commentService.createComment(eq(USER_ID_1), eq(1L), any()))
                .willReturn(10L);

        String body = objectMapper.writeValueAsString(
                Map.of("content", "테스트 depth=0 댓글"));

        mockMvc.perform(post("/api/community/posts/1/comments")
                        .header("Authorization", "Bearer " + TOKEN_USER1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.commentId").value(10));
    }

    @Test
    @DisplayName("A2: 대댓글 정상 등록 (parentCommentId 포함) → 201 Created, commentId=20 반환")
    void createComment_withParent_returns201() throws Exception {
        given(commentService.createComment(eq(USER_ID_1), eq(1L), any()))
                .willReturn(20L);

        String body = objectMapper.writeValueAsString(
                Map.of("content", "대댓글 내용", "parentCommentId", 5));

        mockMvc.perform(post("/api/community/posts/1/comments")
                        .header("Authorization", "Bearer " + TOKEN_USER1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.commentId").value(20));
    }

    @Test
    @DisplayName("A3: MAX_DEPTH_EXCEEDED — depth=1 댓글에 대댓글 시도 → 400, errorCode=MAX_DEPTH_EXCEEDED")
    void createComment_maxDepthExceeded_returns400() throws Exception {
        given(commentService.createComment(eq(USER_ID_1), eq(1L), any()))
                .willThrow(new AuthException("MAX_DEPTH_EXCEEDED",
                        "대댓글에는 대댓글을 달 수 없습니다.", HttpStatus.BAD_REQUEST));

        String body = objectMapper.writeValueAsString(
                Map.of("content", "3단 대댓글 시도", "parentCommentId", 99));

        mockMvc.perform(post("/api/community/posts/1/comments")
                        .header("Authorization", "Bearer " + TOKEN_USER1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("MAX_DEPTH_EXCEEDED"));
    }

    @Test
    @DisplayName("A4: POST_NOT_FOUND — 존재하지 않는 postId → 404, errorCode=POST_NOT_FOUND")
    void createComment_postNotFound_returns404() throws Exception {
        given(commentService.createComment(eq(USER_ID_1), eq(99999L), any()))
                .willThrow(new AuthException("POST_NOT_FOUND",
                        "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        String body = objectMapper.writeValueAsString(
                Map.of("content", "댓글 내용"));

        mockMvc.perform(post("/api/community/posts/99999/comments")
                        .header("Authorization", "Bearer " + TOKEN_USER1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("POST_NOT_FOUND"));
    }

    @Test
    @DisplayName("A5: JWT 없이 댓글 등록 시도 → 401 Unauthorized")
    void createComment_noJwt_returns401() throws Exception {
        String body = objectMapper.writeValueAsString(
                Map.of("content", "인증 없는 댓글"));

        mockMvc.perform(post("/api/community/posts/1/comments")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("A6: content 빈 문자열 (@NotBlank 위반) → 400 Bad Request")
    void createComment_blankContent_returns400() throws Exception {
        String body = objectMapper.writeValueAsString(
                Map.of("content", ""));

        mockMvc.perform(post("/api/community/posts/1/comments")
                        .header("Authorization", "Bearer " + TOKEN_USER1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest());
    }

    // ─────────────────────────────────────────────────────────────
    // B. 댓글 삭제 DELETE /api/community/comments/{commentId}
    // ─────────────────────────────────────────────────────────────

    @Test
    @DisplayName("B1: 본인 JWT로 댓글 정상 삭제 → 200 OK, success=true")
    void deleteComment_owner_returns200() throws Exception {
        willDoNothing().given(commentService).deleteComment(eq(USER_ID_1), eq(5L));

        mockMvc.perform(delete("/api/community/comments/5")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @DisplayName("B2: FORBIDDEN — 타인 JWT로 댓글 삭제 시도 → 403, errorCode=FORBIDDEN")
    void deleteComment_notOwner_returns403() throws Exception {
        willThrow(new AuthException("FORBIDDEN",
                "해당 댓글을 삭제할 권한이 없습니다.", HttpStatus.FORBIDDEN))
                .given(commentService).deleteComment(eq(USER_ID_2), eq(5L));

        mockMvc.perform(delete("/api/community/comments/5")
                        .header("Authorization", "Bearer " + TOKEN_USER2))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("FORBIDDEN"));
    }

    @Test
    @DisplayName("B3: COMMENT_NOT_FOUND — 존재하지 않는 commentId → 404, errorCode=COMMENT_NOT_FOUND")
    void deleteComment_notFound_returns404() throws Exception {
        willThrow(new AuthException("COMMENT_NOT_FOUND",
                "댓글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND))
                .given(commentService).deleteComment(eq(USER_ID_1), eq(99999L));

        mockMvc.perform(delete("/api/community/comments/99999")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("COMMENT_NOT_FOUND"));
    }

    @Test
    @DisplayName("B4: JWT 없이 댓글 삭제 시도 → 401 Unauthorized")
    void deleteComment_noJwt_returns401() throws Exception {
        mockMvc.perform(delete("/api/community/comments/5"))
                .andExpect(status().isUnauthorized());
    }
}
