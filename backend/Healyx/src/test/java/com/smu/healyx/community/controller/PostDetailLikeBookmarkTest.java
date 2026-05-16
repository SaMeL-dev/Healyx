package com.smu.healyx.community.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.config.SecurityConfig;
import com.smu.healyx.common.security.JwtProvider;
import com.smu.healyx.community.dto.PostDetailResponse;
import com.smu.healyx.community.service.CommunityPostService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * PR-3 게시글 상세 조회에서 myLikeExists / myBookmarkExists 필드 검증 테스트.
 *
 * <p>CommunityPostControllerTest(PR-1)는 수정 금지 원칙에 따라 변경하지 않고,
 * 이 파일에서 PR-3 신규 케이스(D1, D2)만 추가 검증한다.
 *
 * <p>전략: @WebMvcTest(CommunityPostController.class) + SecurityConfig import
 * - D1: JWT 있는 사용자 → myLikeExists=true, myBookmarkExists=true 반환 확인
 * - D2: JWT 없는 게스트 → myLikeExists=false, myBookmarkExists=false 반환 확인
 *       (PR-1 C6와 동일 케이스이지만, PR-3 관점에서 명시적으로 재검증)
 */
@WebMvcTest(CommunityPostController.class)
@Import(SecurityConfig.class)
class PostDetailLikeBookmarkTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private CommunityPostService communityPostService;

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
    // D. 게시글 상세 조회 myLikeExists / myBookmarkExists 검증 (PR-3)
    // ──────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("D1: JWT 있음(좋아요+북마크한 사용자) → myLikeExists=true, myBookmarkExists=true")
    void getPostDetail_withJwtLikedAndBookmarked_returnsTrueFlags() throws Exception {
        // given
        PostDetailResponse detail = PostDetailResponse.builder()
                .postId(1L)
                .authorId(2L)
                .authorNickname("작성자")
                .title("제목")
                .content("본문 전체")
                .isBlinded(false)
                .likeCount(10)
                .viewCount(100)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .imageUrls(List.of())
                .myLikeExists(true)
                .myBookmarkExists(true)
                .build();

        given(communityPostService.getPostDetail(eq(1L), eq(USER_ID_1))).willReturn(detail);

        // when & then
        mockMvc.perform(get("/api/community/posts/1")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.postId").value(1))
                .andExpect(jsonPath("$.data.myLikeExists").value(true))
                .andExpect(jsonPath("$.data.myBookmarkExists").value(true));
    }

    @Test
    @DisplayName("D2: JWT 없음(게스트) → myLikeExists=false, myBookmarkExists=false")
    void getPostDetail_guestUser_returnsFalseFlags() throws Exception {
        // given
        PostDetailResponse detail = PostDetailResponse.builder()
                .postId(1L)
                .authorId(2L)
                .authorNickname("작성자")
                .title("제목")
                .content("본문 전체")
                .isBlinded(false)
                .likeCount(10)
                .viewCount(100)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .imageUrls(List.of())
                .myLikeExists(false)
                .myBookmarkExists(false)
                .build();

        given(communityPostService.getPostDetail(eq(1L), isNull())).willReturn(detail);

        // when & then
        mockMvc.perform(get("/api/community/posts/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.myLikeExists").value(false))
                .andExpect(jsonPath("$.data.myBookmarkExists").value(false));
    }

    @Test
    @DisplayName("D3: JWT 있음(좋아요만 한 사용자) → myLikeExists=true, myBookmarkExists=false")
    void getPostDetail_likedOnlyUser_returnsLikeTrueBookmarkFalse() throws Exception {
        // given
        PostDetailResponse detail = PostDetailResponse.builder()
                .postId(1L)
                .authorId(2L)
                .authorNickname("작성자")
                .title("제목")
                .content("본문 전체")
                .isBlinded(false)
                .likeCount(10)
                .viewCount(100)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .imageUrls(List.of())
                .myLikeExists(true)
                .myBookmarkExists(false)
                .build();

        given(communityPostService.getPostDetail(eq(1L), eq(USER_ID_1))).willReturn(detail);

        // when & then
        mockMvc.perform(get("/api/community/posts/1")
                        .header("Authorization", "Bearer " + TOKEN_USER1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.myLikeExists").value(true))
                .andExpect(jsonPath("$.data.myBookmarkExists").value(false));
    }
}
