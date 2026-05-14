package com.smu.healyx.community.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.community.dto.CommentCreateRequest;
import com.smu.healyx.community.service.CommunityCommentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Tag(name = "Community Comment", description = "댓글·대댓글 API")
@RestController
@RequiredArgsConstructor
public class CommunityCommentController {

    private final CommunityCommentService commentService;

    /** HX_COM_006 — 댓글·대댓글 등록 */
    @Operation(summary = "댓글 등록", description = "게시글에 댓글 또는 대댓글을 등록합니다. parentCommentId를 포함하면 대댓글로 처리됩니다.")
    @PostMapping("/api/community/posts/{postId}/comments")
    public ResponseEntity<ApiResponse<Map<String, Long>>> createComment(
            @PathVariable Long postId,
            @RequestBody @Valid CommentCreateRequest request,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        Long commentId = commentService.createComment(userId, postId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(Map.of("commentId", commentId)));
    }

    /** HX_COM_007 — 댓글 삭제 */
    @Operation(summary = "댓글 삭제", description = "댓글을 삭제합니다. 활성 대댓글이 있으면 소프트 삭제(내용 가림), 없으면 하드 삭제합니다.")
    @DeleteMapping("/api/community/comments/{commentId}")
    public ResponseEntity<ApiResponse<Void>> deleteComment(
            @PathVariable Long commentId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        commentService.deleteComment(userId, commentId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
