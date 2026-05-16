package com.smu.healyx.community.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.config.SecurityConfig;
import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.security.JwtProvider;
import com.smu.healyx.community.service.ReportService;
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

import java.util.HashMap;
import java.util.Map;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * CommunityReportController 통합 테스트 (PR-4).
 *
 * <p>전략: @WebMvcTest + SecurityConfig import + JwtProvider MockBean
 * - ReportService MockBean → DB 없이 신고 접수·예외 분기 검증
 * - @Valid 검증(targetType, targetId, reason) 실패 시 400 확인
 */
@WebMvcTest(CommunityReportController.class)
@Import(SecurityConfig.class)
class CommunityReportControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ReportService reportService;

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
    // R1: 정상 신고 → 200 OK
    // ─────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("R1: JWT 있음 + 정상 신고 요청 → 200 OK, success=true")
    void reportContent_validRequest_returns200() throws Exception {
        // given
        willDoNothing().given(reportService).reportContent(eq(USER_ID_1), any());

        Map<String, Object> body = new HashMap<>();
        body.put("targetType", "POST");
        body.put("targetId", 1);
        body.put("reason", "스팸");

        // when & then
        mockMvc.perform(post("/api/community/reports")
                        .header("Authorization", "Bearer " + TOKEN_USER1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    // ─────────────────────────────────────────────────────────────────────
    // R2: 비로그인 신고 → 401
    // ─────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("R2: JWT 없음(비로그인) + 신고 요청 → 401 Unauthorized")
    void reportContent_noJwt_returns401() throws Exception {
        Map<String, Object> body = new HashMap<>();
        body.put("targetType", "POST");
        body.put("targetId", 1);
        body.put("reason", "스팸");

        mockMvc.perform(post("/api/community/reports")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isUnauthorized());
    }

    // ─────────────────────────────────────────────────────────────────────
    // R3: targetType 누락(null) → @NotNull 위반 → 400
    // ─────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("R3: targetType 누락 → @NotNull 위반 → 400 Bad Request")
    void reportContent_missingTargetType_returns400() throws Exception {
        // targetType 필드 자체를 body에서 제외
        Map<String, Object> body = new HashMap<>();
        body.put("targetId", 1);
        body.put("reason", "스팸");

        mockMvc.perform(post("/api/community/reports")
                        .header("Authorization", "Bearer " + TOKEN_USER1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isBadRequest());
    }

    // ─────────────────────────────────────────────────────────────────────
    // R4: reason 공백("") → @NotBlank 위반 → 400
    // ─────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("R4: reason 공백 → @NotBlank 위반 → 400 Bad Request")
    void reportContent_blankReason_returns400() throws Exception {
        Map<String, Object> body = new HashMap<>();
        body.put("targetType", "POST");
        body.put("targetId", 1);
        body.put("reason", "   ");   // 공백만

        mockMvc.perform(post("/api/community/reports")
                        .header("Authorization", "Bearer " + TOKEN_USER1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isBadRequest());
    }

    // ─────────────────────────────────────────────────────────────────────
    // R5: SELF_REPORT_NOT_ALLOWED → 400 Bad Request
    // ─────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("R5: 본인 게시글 신고 → SELF_REPORT_NOT_ALLOWED → 400 Bad Request")
    void reportContent_selfReport_returns400() throws Exception {
        // given — ReportService 가 SELF_REPORT_NOT_ALLOWED 예외 throw
        willThrow(new AuthException("SELF_REPORT_NOT_ALLOWED",
                "본인의 게시글/댓글은 신고할 수 없습니다.", HttpStatus.BAD_REQUEST))
                .given(reportService).reportContent(eq(USER_ID_1), any());

        Map<String, Object> body = new HashMap<>();
        body.put("targetType", "POST");
        body.put("targetId", 5);
        body.put("reason", "스팸");

        // when & then
        mockMvc.perform(post("/api/community/reports")
                        .header("Authorization", "Bearer " + TOKEN_USER1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("SELF_REPORT_NOT_ALLOWED"));
    }

    // ─────────────────────────────────────────────────────────────────────
    // R6: REPORT_DUPLICATE → 409 Conflict
    // ─────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("R6: 중복 신고 → REPORT_DUPLICATE → 409 Conflict")
    void reportContent_duplicate_returns409() throws Exception {
        // given — ReportService 가 REPORT_DUPLICATE 예외 throw
        willThrow(new AuthException("REPORT_DUPLICATE",
                "이미 신고한 대상입니다.", HttpStatus.CONFLICT))
                .given(reportService).reportContent(eq(USER_ID_1), any());

        Map<String, Object> body = new HashMap<>();
        body.put("targetType", "POST");
        body.put("targetId", 1);
        body.put("reason", "스팸");

        // when & then
        mockMvc.perform(post("/api/community/reports")
                        .header("Authorization", "Bearer " + TOKEN_USER1)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errorCode").value("REPORT_DUPLICATE"));
    }
}
