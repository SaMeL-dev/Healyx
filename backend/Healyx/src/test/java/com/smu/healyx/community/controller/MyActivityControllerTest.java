package com.smu.healyx.community.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.config.SecurityConfig;
import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.security.JwtProvider;
import com.smu.healyx.community.dto.BookmarkedPostResponse;
import com.smu.healyx.community.dto.MyCommentResponse;
import com.smu.healyx.community.dto.MyPostResponse;
import com.smu.healyx.community.service.MyActivityService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * MyActivityController 통합 테스트 (PR-3).
 *
 * <p>전략: @WebMvcTest + SecurityConfig import + JwtProvider MockBean
 * - JwtProvider MockBean stub → JwtAuthenticationFilter 실제 동작, JWT 파싱만 대체
 * - MyActivityService MockBean → DB 없이 내 활동 조회·삭제 분기 검증
 * - 북마크 목록(GET /api/community/my/bookmarks) 테스트가 PR-3 핵심 검증 대상
 */
@WebMvcTest(MyActivityController.class)
@Import(SecurityConfig.class)
class MyActivityControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private MyActivityService myActivityService;

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

    // ──────────────────────────────────────────────────────────────────────
    // C. 내 북마크 목록 GET /api/community/my/bookmarks (PR-3 핵심)
    // ──────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("C1: JWT 있음 + 내 북마크 목록 조회 → 200 OK, 목록 반환")
    void getMyBookmarks_withJwt_returns200WithList() throws Exception {
        // given
        BookmarkedPostResponse item = BookmarkedPostResponse.builder()
                .postId(10L)
                .title("내가 북마크한 게시글")
                .author("글쓴이닉네임")
                .contentPreview("내용 미리보기 20자...")
                .likeCount(7)
                .build();
        given(myActivityService.getMyBookmarks(USER_ID_1)).willReturn(List.of(item));

        // when & then
        mockMvc.perform(get("/api/community/my/bookmarks")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].postId").value(10))
                .andExpect(jsonPath("$.data[0].title").value("내가 북마크한 게시글"))
                .andExpect(jsonPath("$.data[0].author").value("글쓴이닉네임"))
                .andExpect(jsonPath("$.data[0].likeCount").value(7));
    }

    @Test
    @DisplayName("C2: JWT 없음(비로그인) + 내 북마크 목록 조회 → 401 Unauthorized")
    void getMyBookmarks_noJwt_returns401() throws Exception {
        mockMvc.perform(get("/api/community/my/bookmarks"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("C3: JWT 있음 + 북마크 없는 사용자 → 200 OK, 빈 목록 반환")
    void getMyBookmarks_emptyList_returns200WithEmptyList() throws Exception {
        // given
        given(myActivityService.getMyBookmarks(USER_ID_1)).willReturn(List.of());

        // when & then
        mockMvc.perform(get("/api/community/my/bookmarks")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data").isEmpty());
    }

    // ──────────────────────────────────────────────────────────────────────
    // E. 내 게시글 목록 GET /api/community/my/posts
    // ──────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("E1: JWT 있음 + 내 게시글 목록 조회 → 200 OK")
    void getMyPosts_withJwt_returns200() throws Exception {
        // given
        given(myActivityService.getMyPosts(USER_ID_1)).willReturn(List.of());

        // when & then
        mockMvc.perform(get("/api/community/my/posts")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    @DisplayName("E2: JWT 없음 + 내 게시글 목록 조회 → 401 Unauthorized")
    void getMyPosts_noJwt_returns401() throws Exception {
        mockMvc.perform(get("/api/community/my/posts"))
                .andExpect(status().isUnauthorized());
    }

    // ──────────────────────────────────────────────────────────────────────
    // F. 내 게시글 삭제 DELETE /api/community/my/posts/{postId}
    // ──────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("F1: JWT 있음 + 내 게시글 삭제 → 200 OK")
    void deleteMyPost_withJwt_returns200() throws Exception {
        // given
        willDoNothing().given(myActivityService).deleteMyPost(USER_ID_1, 1L);

        // when & then
        mockMvc.perform(delete("/api/community/my/posts/1")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @DisplayName("F2: JWT 없음 + 내 게시글 삭제 → 401 Unauthorized")
    void deleteMyPost_noJwt_returns401() throws Exception {
        mockMvc.perform(delete("/api/community/my/posts/1"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("F3: 존재하지 않는 게시글 삭제 → 404 Not Found, POST_NOT_FOUND")
    void deleteMyPost_postNotFound_returns404() throws Exception {
        // given
        willThrow(new AuthException("POST_NOT_FOUND",
                "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND))
                .given(myActivityService).deleteMyPost(USER_ID_1, 99999L);

        // when & then
        mockMvc.perform(delete("/api/community/my/posts/99999")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("POST_NOT_FOUND"));
    }

    @Test
    @DisplayName("F4: 타인 게시글 삭제 시도 → 403 Forbidden, ACCESS_DENIED")
    void deleteMyPost_accessDenied_returns403() throws Exception {
        // given
        willThrow(new AuthException("ACCESS_DENIED",
                "해당 게시글을 삭제할 권한이 없습니다.", HttpStatus.FORBIDDEN))
                .given(myActivityService).deleteMyPost(USER_ID_1, 2L);

        // when & then
        mockMvc.perform(delete("/api/community/my/posts/2")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("ACCESS_DENIED"));
    }

    // ──────────────────────────────────────────────────────────────────────
    // G. 내 댓글 삭제 DELETE /api/community/my/comments/{commentId}
    // ──────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("G1: JWT 있음 + 내 댓글 삭제 → 200 OK")
    void deleteMyComment_withJwt_returns200() throws Exception {
        // given
        willDoNothing().given(myActivityService).deleteMyComment(USER_ID_1, 5L);

        // when & then
        mockMvc.perform(delete("/api/community/my/comments/5")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @DisplayName("G2: JWT 없음 + 내 댓글 삭제 → 401 Unauthorized")
    void deleteMyComment_noJwt_returns401() throws Exception {
        mockMvc.perform(delete("/api/community/my/comments/5"))
                .andExpect(status().isUnauthorized());
    }
}
