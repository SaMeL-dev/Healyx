package com.smu.healyx.community.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.community.dto.ToggleLikeResponse;
import com.smu.healyx.community.service.CommunityLikeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Community Like", description = "커뮤니티 좋아요 API")
@RestController
@RequestMapping("/api/community/posts")
@RequiredArgsConstructor
public class CommunityLikeController {

    private final CommunityLikeService communityLikeService;

    /** HX_COM_012 — 좋아요 토글 (POST → 좋아요 추가, 이미 있으면 취소) */
    @Operation(summary = "좋아요 토글", description = "좋아요가 없으면 추가, 이미 있으면 취소합니다.")
    @PostMapping("/{postId}/likes")
    public ResponseEntity<ApiResponse<ToggleLikeResponse>> toggleLike(
            @PathVariable Long postId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(communityLikeService.toggleLike(userId, postId)));
    }
}
