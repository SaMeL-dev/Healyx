package com.smu.healyx.community.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.community.dto.BookmarkedPostResponse;
import com.smu.healyx.community.service.CommunityBookmarkService;
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

@Tag(name = "Community Bookmark", description = "커뮤니티 북마크 API")
@RestController
@RequestMapping("/api/community/bookmarks")
@RequiredArgsConstructor
public class CommunityBookmarkController {

    private final CommunityBookmarkService communityBookmarkService;

    /** 북마크한 게시글 목록 조회 — JWT 필요 */
    @Operation(summary = "북마크 목록 조회", description = "북마크한 게시글을 등록 최신순으로 반환합니다.")
    @GetMapping
    public ResponseEntity<ApiResponse<List<BookmarkedPostResponse>>> getBookmarkedPosts(
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(communityBookmarkService.getBookmarkedPosts(userId)));
    }

    /** 북마크 삭제 — JWT 필요 */
    @Operation(summary = "북마크 삭제", description = "해당 게시글의 북마크를 삭제합니다.")
    @DeleteMapping("/{postId}")
    public ResponseEntity<ApiResponse<Void>> deleteBookmark(
            @PathVariable Long postId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        communityBookmarkService.deleteBookmark(userId, postId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
