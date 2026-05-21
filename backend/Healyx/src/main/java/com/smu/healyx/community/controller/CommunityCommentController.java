package com.smu.healyx.community.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.community.dto.CommentCreateRequest;
import com.smu.healyx.community.dto.CommentTranslationResponse;
import com.smu.healyx.community.dto.CommentUpdateRequest;
import com.smu.healyx.community.service.CommunityCommentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Pattern;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Tag(name = "Community Comment", description = "댓글·대댓글 API")
@RestController
@RequiredArgsConstructor
@Validated
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

    /** 댓글 수정 */
    @Operation(summary = "댓글 수정", description = "본인이 작성한 댓글의 내용을 수정합니다. 소프트 삭제된 댓글은 수정할 수 없습니다.")
    @PutMapping("/api/community/comments/{commentId}")
    public ResponseEntity<ApiResponse<Void>> updateComment(
            @PathVariable Long commentId,
            @RequestBody @Valid CommentUpdateRequest request,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        commentService.updateComment(userId, commentId, request);
        return ResponseEntity.ok(ApiResponse.success(null));
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

    /** COM-011 — 댓글 번역 (게스트 허용) */
    @Operation(summary = "댓글 번역", description = "댓글 내용을 지정 언어로 번역합니다. lang: ko|en|zh|vi|th|ja. 인증 불필요.")
    @GetMapping("/api/community/comments/{commentId}/translate")
    public ResponseEntity<ApiResponse<CommentTranslationResponse>> translateComment(
            @PathVariable Long commentId,
            @RequestParam
            @Pattern(regexp = "^(ko|en|zh|vi|th|ja)$", message = "지원하지 않는 언어 코드입니다.")
            String lang) {
        return ResponseEntity.ok(ApiResponse.success(commentService.translateComment(commentId, lang)));
    }
}
