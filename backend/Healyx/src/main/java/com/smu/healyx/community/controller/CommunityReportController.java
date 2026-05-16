package com.smu.healyx.community.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.community.dto.ReportRequest;
import com.smu.healyx.community.service.ReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Community Report", description = "커뮤니티 신고 API")
@RestController
@RequestMapping("/api/community")
@RequiredArgsConstructor
public class CommunityReportController {

    private final ReportService reportService;

    /** HX_COM_009 — 게시글/댓글 신고 */
    @Operation(summary = "신고", description = "게시글 또는 댓글을 신고합니다. 5건 누적 시 자동 블라인드 처리됩니다.")
    @PostMapping("/reports")
    public ResponseEntity<ApiResponse<Void>> reportContent(
            @Valid @RequestBody ReportRequest request,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        reportService.reportContent(userId, request);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
