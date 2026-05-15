package com.smu.healyx.community.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.config.SecurityConfig;
import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.security.JwtProvider;
import com.smu.healyx.community.dto.BookmarkedPostResponse;
import com.smu.healyx.community.dto.ToggleBookmarkResponse;
import com.smu.healyx.community.service.CommunityBookmarkService;
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
 * CommunityBookmarkController 통합 테스트 (PR-3).
 *
 * <p>전략: @WebMvcTest + SecurityConfig import + JwtProvider MockBean
 * - JwtProvider MockBean stub → JwtAuthenticationFilter 실제 동작, JWT 파싱만 대체
 * - CommunityBookmarkService MockBean → DB 없이 북마크 토글·조회·삭제 분기 검증
 */
@WebMvcTest(CommunityBookmarkController.class)
@Import(SecurityConfig.class)
class CommunityBookmarkControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private CommunityBookmarkService communityBookmarkService;

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
    // B. 북마크 토글 POST /api/community/posts/{postId}/bookmarks
    // ──────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("B1: JWT 있음 + 첫 북마크 → 200 OK, bookmarked=true")
    void toggleBookmark_firstBookmark_returns200BookmarkedTrue() throws Exception {
        // given
        given(communityBookmarkService.toggleBookmark(USER_ID_1, 1L))
                .willReturn(new ToggleBookmarkResponse(true));

        // when & then
        mockMvc.perform(post("/api/community/posts/1/bookmarks")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.bookmarked").value(true));
    }

    @Test
    @DisplayName("B2: JWT 있음 + 이미 북마크(취소) → 200 OK, bookmarked=false")
    void toggleBookmark_cancelBookmark_returns200BookmarkedFalse() throws Exception {
        // given
        given(communityBookmarkService.toggleBookmark(USER_ID_1, 1L))
                .willReturn(new ToggleBookmarkResponse(false));

        // when & then
        mockMvc.perform(post("/api/community/posts/1/bookmarks")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.bookmarked").value(false));
    }

    @Test
    @DisplayName("B3: JWT 없음(비로그인) + 북마크 토글 → 401 Unauthorized")
    void toggleBookmark_noJwt_returns401() throws Exception {
        mockMvc.perform(post("/api/community/posts/1/bookmarks"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("B4: 존재하지 않는 postId 북마크 → 404 Not Found, POST_NOT_FOUND")
    void toggleBookmark_postNotFound_returns404() throws Exception {
        // given
        given(communityBookmarkService.toggleBookmark(USER_ID_1, 99999L))
                .willThrow(new AuthException("POST_NOT_FOUND",
                        "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        // when & then
        mockMvc.perform(post("/api/community/posts/99999/bookmarks")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("POST_NOT_FOUND"));
    }

    // ──────────────────────────────────────────────────────────────────────
    // C. 북마크 목록 조회 GET /api/community/bookmarks
    // ──────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("C1: JWT 있음 + 북마크 목록 조회 → 200 OK, 목록 반환")
    void getBookmarkedPosts_withJwt_returns200WithList() throws Exception {
        // given
        BookmarkedPostResponse item = BookmarkedPostResponse.builder()
                .postId(10L)
                .title("북마크한 게시글")
                .author("작성자닉")
                .contentPreview("내용 미리보기...")
                .likeCount(5)
                .build();
        given(communityBookmarkService.getBookmarkedPosts(USER_ID_1))
                .willReturn(List.of(item));

        // when & then
        mockMvc.perform(get("/api/community/bookmarks")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].postId").value(10))
                .andExpect(jsonPath("$.data[0].title").value("북마크한 게시글"))
                .andExpect(jsonPath("$.data[0].author").value("작성자닉"))
                .andExpect(jsonPath("$.data[0].likeCount").value(5));
    }

    @Test
    @DisplayName("C2: JWT 없음(비로그인) + 북마크 목록 조회 → 401 Unauthorized")
    void getBookmarkedPosts_noJwt_returns401() throws Exception {
        mockMvc.perform(get("/api/community/bookmarks"))
                .andExpect(status().isUnauthorized());
    }

    // ──────────────────────────────────────────────────────────────────────
    // D. 북마크 삭제 DELETE /api/community/bookmarks/{postId}
    // ──────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("D1: JWT 있음 + 북마크 정상 삭제 → 200 OK, success=true")
    void deleteBookmark_withJwt_returns200() throws Exception {
        // given
        willDoNothing().given(communityBookmarkService).deleteBookmark(USER_ID_1, 1L);

        // when & then
        mockMvc.perform(delete("/api/community/bookmarks/1")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    @DisplayName("D2: JWT 없음 + 북마크 삭제 → 401 Unauthorized")
    void deleteBookmark_noJwt_returns401() throws Exception {
        mockMvc.perform(delete("/api/community/bookmarks/1"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("D3: 북마크 없는 게시글 삭제 → 404 Not Found, BOOKMARK_NOT_FOUND")
    void deleteBookmark_notFound_returns404() throws Exception {
        // given
        willThrow(new AuthException("BOOKMARK_NOT_FOUND",
                "해당 게시글의 북마크 내역이 없습니다.", HttpStatus.NOT_FOUND))
                .given(communityBookmarkService).deleteBookmark(USER_ID_1, 99999L);

        // when & then
        mockMvc.perform(delete("/api/community/bookmarks/99999")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("BOOKMARK_NOT_FOUND"));
    }
}
