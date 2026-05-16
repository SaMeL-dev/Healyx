package com.smu.healyx.community.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.community.dto.BookmarkedPostResponse;
import com.smu.healyx.community.dto.MyCommentResponse;
import com.smu.healyx.community.dto.MyPostResponse;
import com.smu.healyx.community.service.MyActivityService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "My Activity", description = "내 게시글·댓글 보관함 API")
@RestController
@RequestMapping("/api/community/my")
@RequiredArgsConstructor
public class MyActivityController {

    private final MyActivityService myActivityService;

    /** 내가 쓴 게시글 목록 — JWT 필요 */
    @Operation(summary = "내 게시글 목록 조회", description = "본인이 작성한 게시글을 최신순으로 반환합니다.")
    @GetMapping("/posts")
    public ResponseEntity<ApiResponse<List<MyPostResponse>>> getMyPosts(
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(myActivityService.getMyPosts(userId)));
    }

    /** HX_M_005 — 내 북마크 목록 — JWT 필요 */
    @Operation(summary = "내 북마크 목록 조회", description = "본인이 북마크한 게시글을 등록 최신순으로 반환합니다.")
    @GetMapping("/bookmarks")
    public ResponseEntity<ApiResponse<List<BookmarkedPostResponse>>> getMyBookmarks(
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(myActivityService.getMyBookmarks(userId)));
    }

    /** 내가 쓴 댓글 목록 — JWT 필요 */
    @Operation(summary = "내 댓글 목록 조회", description = "본인이 작성한 댓글(삭제 제외)을 최신순으로 반환합니다.")
    @GetMapping("/comments")
    public ResponseEntity<ApiResponse<List<MyCommentResponse>>> getMyComments(
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(myActivityService.getMyComments(userId)));
    }

    /** 내 게시글 삭제 — JWT 필요 */
    @Operation(summary = "내 게시글 삭제", description = "본인이 작성한 게시글을 소프트 삭제합니다.")
    @DeleteMapping("/posts/{postId}")
    public ResponseEntity<ApiResponse<Void>> deleteMyPost(
            @PathVariable Long postId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        myActivityService.deleteMyPost(userId, postId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /** 내 댓글 삭제 — JWT 필요 */
    @Operation(summary = "내 댓글 삭제", description = "본인이 작성한 댓글을 소프트 삭제합니다. 대댓글이 있으면 내용을 '삭제된 댓글입니다'로 대체합니다.")
    @DeleteMapping("/comments/{commentId}")
    public ResponseEntity<ApiResponse<Void>> deleteMyComment(
            @PathVariable Long commentId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        myActivityService.deleteMyComment(userId, commentId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
