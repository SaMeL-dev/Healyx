package com.smu.healyx.community.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.community.dto.BookmarkedPostResponse;
import com.smu.healyx.community.dto.ToggleBookmarkResponse;
import com.smu.healyx.community.service.CommunityBookmarkService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "Community Bookmark", description = "커뮤니티 북마크 API")
@RestController
@RequestMapping("/api/community")
@RequiredArgsConstructor
public class CommunityBookmarkController {

    private final CommunityBookmarkService communityBookmarkService;

    /** HX_COM_014 — 북마크 토글 (POST → 북마크 추가, 이미 있으면 취소) */
    @Operation(summary = "북마크 토글", description = "북마크가 없으면 추가, 이미 있으면 취소합니다.")
    @PostMapping("/posts/{postId}/bookmarks")
    public ResponseEntity<ApiResponse<ToggleBookmarkResponse>> toggleBookmark(
            @PathVariable Long postId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(communityBookmarkService.toggleBookmark(userId, postId)));
    }

    /** 북마크한 게시글 목록 조회 — JWT 필요 */
    @Operation(summary = "북마크 목록 조회", description = "북마크한 게시글을 등록 최신순으로 반환합니다.")
    @GetMapping("/bookmarks")
    public ResponseEntity<ApiResponse<List<BookmarkedPostResponse>>> getBookmarkedPosts(
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(communityBookmarkService.getBookmarkedPosts(userId)));
    }

    /** 북마크 삭제 — JWT 필요 */
    @Operation(summary = "북마크 삭제", description = "해당 게시글의 북마크를 삭제합니다.")
    @DeleteMapping("/bookmarks/{postId}")
    public ResponseEntity<ApiResponse<Void>> deleteBookmark(
            @PathVariable Long postId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        communityBookmarkService.deleteBookmark(userId, postId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
