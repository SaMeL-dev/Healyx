package com.smu.healyx.community.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.config.MessageSourceConfig;
import com.smu.healyx.common.config.SecurityConfig;
import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.exception.ExternalApiException;
import com.smu.healyx.common.filter.LocaleFilter;
import com.smu.healyx.common.security.JwtProvider;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import com.smu.healyx.community.dto.CommentTranslationResponse;
import com.smu.healyx.community.dto.PostListItemResponse;
import com.smu.healyx.community.dto.PostTranslationResponse;
import com.smu.healyx.community.service.CommunityCommentService;
import com.smu.healyx.community.service.CommunityPostService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Locale;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * 커뮤니티 다국어 기능 통합 테스트 (COM-008, COM-011, i18n 에러 메시지).
 *
 * <p>전략: @WebMvcTest — CommunityPostController + CommunityCommentController 슬라이스
 * - LocaleFilter는 @Component 이므로 WebMvcTest 슬라이스에 자동 포함 → Accept-Language 헤더 처리 실제 동작
 * - MessageSource는 실제 빈 사용 → errors_*.properties, business_*.properties 로드 검증 포함
 * - CommunityPostService / CommunityCommentService → MockBean (DB 없이 분기 검증)
 * - JwtProvider → MockBean (JWT 파싱 대체)
 *
 * <p>Feature 1 (COM-008): searchPosts가 한국어가 아닌 locale에서 번역된 keyword로 서비스를 호출하는지 검증.
 *   - @WebMvcTest 슬라이스에서는 서비스 내부 TranslationService를 직접 mock할 수 없으므로,
 *     서비스의 searchPosts() 가 어떤 keyword 값으로 호출됐는지를 ArgumentCaptor로 검증하는 대신
 *     서비스 계층 자체를 stub하여 HTTP 레이어 흐름(200 OK, 파라미터 전달 여부)을 검증한다.
 *   - 번역 호출 여부(TranslationService.translate 실제 호출)는 서비스 단위 테스트 영역임을 주석으로 명시.
 *
 * <p>Feature 2 (COM-011): 게시글/댓글 번역 엔드포인트 동작 검증.
 * <p>Feature 3 (i18n): Accept-Language 헤더 기반 에러 메시지 다국어 검증.
 */
@WebMvcTest({CommunityPostController.class, CommunityCommentController.class})
@Import({SecurityConfig.class, LocaleFilter.class, MessageSourceConfig.class})
class CommunityTranslationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private CommunityPostService communityPostService;

    @MockBean
    private CommunityCommentService communityCommentService;

    @MockBean
    private JwtProvider jwtProvider;

    // ────────────────────────────────────────────────────────
    // Setup
    // ────────────────────────────────────────────────────────

    @BeforeEach
    void setUpJwtMock() {
        // 인증이 필요 없는 엔드포인트 위주이므로 최소 JWT stub만 설정
        given(jwtProvider.validateToken(anyString())).willReturn(false);
    }

    // ────────────────────────────────────────────────────────
    // Feature 1: COM-008 — 검색 키워드 번역
    // ────────────────────────────────────────────────────────

    /**
     * F1-1: Accept-Language:en + keyword 포함 검색 요청 → 200 OK.
     *
     * <p>searchPosts()는 HTTP 레이어에서 keyword 파라미터를 그대로 서비스에 전달한다.
     * 서비스 내부에서 LocaleContextHolder를 통해 "en" locale을 감지하고
     * TranslationService.translate(keyword, "ko")를 호출하는 로직은 서비스 레이어 책임이므로,
     * 이 테스트는 HTTP 200 정상 응답 및 서비스 호출 여부만 검증한다.
     * (서비스 내 번역 호출 검증 → CommunityPostServiceTest에서 수행 권장)
     */
    @Test
    @DisplayName("F1-1: Accept-Language:en + keyword 영어 검색 → 200 OK, searchPosts 호출 확인")
    void searchPosts_withEnglishKeyword_returns200() throws Exception {
        Page<PostListItemResponse> emptyPage = new PageImpl<>(List.of(), PageRequest.of(0, 10), 0);
        given(communityPostService.searchPosts(any(), eq("all"), eq("latest"), eq(0), eq(10)))
                .willReturn(emptyPage);

        mockMvc.perform(get("/api/community/posts")
                        .param("keyword", "headache")
                        .header("Accept-Language", "en"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        // 서비스가 keyword 인자를 받아 호출됐는지 확인 (번역 여부는 서비스 단위테스트 영역)
        then(communityPostService).should().searchPosts(eq("headache"), eq("all"), eq("latest"), eq(0), eq(10));
    }

    /**
     * F1-2: TranslationService가 ExternalApiException을 던졌을 때 fail-open.
     *
     * <p>서비스의 fail-open 로직(catch ExternalApiException → 원본 keyword 사용)은
     * 서비스 레이어 내부 검증 영역이다. 이 테스트는 외부 번역 실패와 무관하게
     * HTTP 레이어가 200을 정상 반환함을 검증하기 위해 서비스 stub을 정상 반환으로 설정한다.
     */
    @Test
    @DisplayName("F1-2: 번역 실패 시 fail-open — 서비스는 정상 응답 200 반환")
    void searchPosts_withDeepLFailure_returns200() throws Exception {
        Page<PostListItemResponse> emptyPage = new PageImpl<>(List.of(), PageRequest.of(0, 10), 0);
        // 서비스 자체는 ExternalApiException을 내부에서 catch하고 정상 Page를 반환하도록 stub
        given(communityPostService.searchPosts(eq("headache"), eq("all"), eq("latest"), eq(0), eq(10)))
                .willReturn(emptyPage);

        mockMvc.perform(get("/api/community/posts")
                        .param("keyword", "headache")
                        .header("Accept-Language", "en"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    /**
     * F1-3: Accept-Language:ko → 한국어이면 서비스에 keyword 그대로 전달, 200 OK.
     */
    @Test
    @DisplayName("F1-3: Accept-Language:ko → 번역 없이 searchPosts 정상 호출 200 OK")
    void searchPosts_withKoreanLocale_returns200() throws Exception {
        Page<PostListItemResponse> emptyPage = new PageImpl<>(List.of(), PageRequest.of(0, 10), 0);
        given(communityPostService.searchPosts(any(), eq("all"), eq("latest"), eq(0), eq(10)))
                .willReturn(emptyPage);

        mockMvc.perform(get("/api/community/posts")
                        .param("keyword", "두통")
                        .header("Accept-Language", "ko"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        then(communityPostService).should()
                .searchPosts(eq("두통"), eq("all"), eq("latest"), eq(0), eq(10));
    }

    // ────────────────────────────────────────────────────────
    // Feature 2: COM-011 — 게시글 번역 엔드포인트
    // ────────────────────────────────────────────────────────

    @Test
    @DisplayName("F2-1: translatePost — 정상 게시글, lang=en → 200 OK, translatedTitle/Content 검증")
    void translatePost_success_returns200() throws Exception {
        PostTranslationResponse response = PostTranslationResponse.builder()
                .postId(1L)
                .lang("en")
                .translatedTitle("Hospital Review")
                .translatedContent("The hospital was very clean.")
                .originalTitle("병원 후기")
                .originalContent("병원이 매우 깔끔했습니다.")
                .build();

        given(communityPostService.translatePost(eq(1L), eq("en"))).willReturn(response);

        mockMvc.perform(get("/api/community/posts/1/translate")
                        .param("lang", "en"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.postId").value(1))
                .andExpect(jsonPath("$.data.lang").value("en"))
                .andExpect(jsonPath("$.data.translatedTitle").value("Hospital Review"))
                .andExpect(jsonPath("$.data.translatedContent").value("The hospital was very clean."))
                .andExpect(jsonPath("$.data.originalTitle").value("병원 후기"))
                .andExpect(jsonPath("$.data.originalContent").value("병원이 매우 깔끔했습니다."));
    }

    @Test
    @DisplayName("F2-2: translatePost — 블라인드 게시글, lang=en → 200 OK, blinded 메시지 반환")
    void translatePost_blindedPost_returnsBlindedMessage() throws Exception {
        // 서비스는 블라인드 게시글에 대해 business_en.properties의 post.blinded 메시지를 반환
        PostTranslationResponse response = PostTranslationResponse.builder()
                .postId(5L)
                .lang("en")
                .translatedTitle("This post has been hidden due to reports.")
                .translatedContent("This post has been hidden due to reports.")
                .originalTitle("블라인드 게시글")
                .originalContent(null)   // 블라인드 시 null
                .build();

        given(communityPostService.translatePost(eq(5L), eq("en"))).willReturn(response);

        mockMvc.perform(get("/api/community/posts/5/translate")
                        .param("lang", "en"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.translatedTitle").value("This post has been hidden due to reports."))
                .andExpect(jsonPath("$.data.translatedContent").value("This post has been hidden due to reports."))
                .andExpect(jsonPath("$.data.originalContent").doesNotExist());
    }

    @Test
    @DisplayName("F2-3: translatePost — 없는 postId → 404 Not Found, POST_NOT_FOUND")
    void translatePost_notFound_returns404() throws Exception {
        given(communityPostService.translatePost(eq(99999L), eq("en")))
                .willThrow(new AuthException("POST_NOT_FOUND", "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        mockMvc.perform(get("/api/community/posts/99999/translate")
                        .param("lang", "en"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("POST_NOT_FOUND"));
    }

    @Test
    @DisplayName("F2-4: translatePost — 지원하지 않는 lang=invalid → 400 Bad Request, INVALID_INPUT")
    void translatePost_invalidLang_returns400() throws Exception {
        // @Pattern 검증 실패 → ConstraintViolationException → GlobalExceptionHandler → 400
        mockMvc.perform(get("/api/community/posts/1/translate")
                        .param("lang", "invalid"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("INVALID_INPUT"));
    }

    // ────────────────────────────────────────────────────────
    // Feature 2: COM-011 — 댓글 번역 엔드포인트
    // ────────────────────────────────────────────────────────

    @Test
    @DisplayName("F2-5: translateComment — 정상 댓글, lang=zh → 200 OK, translatedContent 검증")
    void translateComment_success_returns200() throws Exception {
        CommentTranslationResponse response = CommentTranslationResponse.builder()
                .commentId(10L)
                .lang("zh")
                .translatedContent("医院非常干净。")
                .originalContent("병원이 매우 깔끔했습니다.")
                .build();

        given(communityCommentService.translateComment(eq(10L), eq("zh"))).willReturn(response);

        mockMvc.perform(get("/api/community/comments/10/translate")
                        .param("lang", "zh"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.commentId").value(10))
                .andExpect(jsonPath("$.data.lang").value("zh"))
                .andExpect(jsonPath("$.data.translatedContent").value("医院非常干净。"))
                .andExpect(jsonPath("$.data.originalContent").value("병원이 매우 깔끔했습니다."));
    }

    @Test
    @DisplayName("F2-6: translateComment — 소프트 삭제된 댓글, lang=en → 200 OK, deleted 메시지 반환")
    void translateComment_deletedComment_returnsDeletedMessage() throws Exception {
        // 서비스는 삭제된 댓글에 business_en.properties의 comment.deleted 메시지를 반환
        CommentTranslationResponse response = CommentTranslationResponse.builder()
                .commentId(20L)
                .lang("en")
                .translatedContent("This comment has been deleted.")
                .originalContent(null)  // 삭제된 경우 null
                .build();

        given(communityCommentService.translateComment(eq(20L), eq("en"))).willReturn(response);

        mockMvc.perform(get("/api/community/comments/20/translate")
                        .param("lang", "en"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.translatedContent").value("This comment has been deleted."))
                .andExpect(jsonPath("$.data.originalContent").doesNotExist());
    }

    @Test
    @DisplayName("F2-7: translateComment — 없는 commentId → 404 Not Found, COMMENT_NOT_FOUND")
    void translateComment_notFound_returns404() throws Exception {
        given(communityCommentService.translateComment(eq(99999L), eq("en")))
                .willThrow(new AuthException("COMMENT_NOT_FOUND", "댓글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        mockMvc.perform(get("/api/community/comments/99999/translate")
                        .param("lang", "en"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("COMMENT_NOT_FOUND"));
    }

    @Test
    @DisplayName("F2-8: translateComment — 지원하지 않는 lang=abc → 400 Bad Request, INVALID_INPUT")
    void translateComment_invalidLang_returns400() throws Exception {
        mockMvc.perform(get("/api/community/comments/1/translate")
                        .param("lang", "abc"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("INVALID_INPUT"));
    }

    // ────────────────────────────────────────────────────────
    // Feature 3: i18n 에러 메시지 다국어 검증
    //
    // GlobalExceptionHandler.resolveMessage()가 LocaleContextHolder locale 기반으로
    // MessageSource(errors_*.properties)에서 메시지를 조회한다.
    //
    // @WebMvcTest 슬라이스에서 LocaleFilter가 addFilterBefore로 Security 필터 체인에 등록되지만
    // MockMvc 요청 처리 중에 LocaleFilter 실행이 보장되지 않으므로,
    // F3 테스트에서는 LocaleContextHolder.setLocale()을 직접 설정하여 locale을 제어한다.
    // MockMvc는 동일 스레드에서 동기적으로 요청을 처리하므로 LocaleContextHolder(기본 THREAD 상속)가 유효하다.
    // ────────────────────────────────────────────────────────

    /**
     * MockHttpServletRequest에 preferred locale을 추가하는 헬퍼.
     * DispatcherServlet의 AcceptHeaderLocaleResolver가 request.getLocale()을 읽어
     * LocaleContextHolder에 설정하므로, 이 방식으로 locale을 제어한다.
     */
    private static RequestPostProcessor withLocale(Locale locale) {
        return request -> {
            request.addPreferredLocale(locale);
            return request;
        };
    }

    @Test
    @DisplayName("F3-1: preferred locale=en + 없는 postId 번역 요청 → 영어 에러 메시지 반환")
    void errorMessage_withEnglishLocale_returnsEnglishMessage() throws Exception {
        given(communityPostService.translatePost(eq(99999L), eq("en")))
                .willThrow(new AuthException("POST_NOT_FOUND", "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        mockMvc.perform(get("/api/community/posts/99999/translate")
                        .param("lang", "en")
                        .with(withLocale(Locale.ENGLISH)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("POST_NOT_FOUND"))
                // errors_en.properties: POST_NOT_FOUND=Post not found.
                .andExpect(jsonPath("$.message").value("Post not found."));
    }

    @Test
    @DisplayName("F3-2: preferred locale=zh + 없는 postId 번역 요청 → 중국어 에러 메시지 반환")
    void errorMessage_withChineseLocale_returnsChineseMessage() throws Exception {
        given(communityPostService.translatePost(eq(99999L), eq("zh")))
                .willThrow(new AuthException("POST_NOT_FOUND", "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        // zh-CN 매핑: LocaleFilter와 동일하게 Locale.forLanguageTag("zh-CN") 사용
        mockMvc.perform(get("/api/community/posts/99999/translate")
                        .param("lang", "zh")
                        .with(withLocale(Locale.forLanguageTag("zh-CN"))))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("POST_NOT_FOUND"))
                // errors_zh.properties: POST_NOT_FOUND=找不到该帖子。
                .andExpect(jsonPath("$.message").value("找不到该帖子。"));
    }

    @Test
    @DisplayName("F3-3: preferred locale=ko 설정 → 한국어 에러 메시지 반환")
    void errorMessage_withKoreanLocale_returnsKoreanMessage() throws Exception {
        // MockHttpServletRequest의 기본 locale은 Locale.ENGLISH이므로,
        // 한국어 메시지를 검증하려면 preferred locale을 명시적으로 Locale.KOREAN으로 설정해야 한다.
        given(communityPostService.translatePost(eq(99999L), eq("en")))
                .willThrow(new AuthException("POST_NOT_FOUND", "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        mockMvc.perform(get("/api/community/posts/99999/translate")
                        .param("lang", "en")
                        .with(withLocale(Locale.KOREAN)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("POST_NOT_FOUND"))
                // errors_ko.properties: POST_NOT_FOUND=게시글을 찾을 수 없습니다.
                .andExpect(jsonPath("$.message").value("게시글을 찾을 수 없습니다."));
    }

    @Test
    @DisplayName("F3-4: preferred locale=en + 없는 commentId 번역 요청 → 영어 에러 메시지 반환")
    void errorMessage_commentNotFound_withEnglishLocale_returnsEnglishMessage() throws Exception {
        given(communityCommentService.translateComment(eq(99999L), eq("en")))
                .willThrow(new AuthException("COMMENT_NOT_FOUND", "댓글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        mockMvc.perform(get("/api/community/comments/99999/translate")
                        .param("lang", "en")
                        .with(withLocale(Locale.ENGLISH)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("COMMENT_NOT_FOUND"))
                // errors_en.properties: COMMENT_NOT_FOUND=Comment not found.
                .andExpect(jsonPath("$.message").value("Comment not found."));
    }
}
