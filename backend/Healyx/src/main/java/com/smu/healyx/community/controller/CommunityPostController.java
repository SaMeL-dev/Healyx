package com.smu.healyx.community.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.community.dto.PostDetailResponse;
import com.smu.healyx.community.dto.PostListItemResponse;
import com.smu.healyx.community.dto.PostTranslationResponse;
import com.smu.healyx.community.service.CommunityPostService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Pattern;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@Tag(name = "Community Posts", description = "커뮤니티 게시글 API")
@RestController
@RequestMapping("/api/community/posts")
@RequiredArgsConstructor
@Validated
public class CommunityPostController {

    private final CommunityPostService communityPostService;

    /** HX_COM_002 — 게시글 등록 */
    @Operation(summary = "게시글 등록", description = "제목·본문(필수), 이미지(선택, 최대 5장). JWT 필요.")
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<Map<String, Long>>> createPost(
            @RequestPart("title") String title,
            @RequestPart("content") String content,
            @RequestPart(value = "images", required = false) List<MultipartFile> images,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        Long postId = communityPostService.createPost(userId, title, content, images);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(Map.of("postId", postId)));
    }

    /** HX_COM_008 — 게시글 목록 조회 + 검색 (게스트 허용) */
    @Operation(summary = "게시글 목록·검색", description = "keyword 없으면 전체 목록. searchField: title/content/all. sort: latest/popular.")
    @GetMapping
    public ResponseEntity<ApiResponse<Page<PostListItemResponse>>> searchPosts(
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "all") String searchField,
            @RequestParam(defaultValue = "latest") String sort,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(ApiResponse.success(
                communityPostService.searchPosts(keyword, searchField, sort, page, size)));
    }

    /** HX_COM_015 — 게시글 상세 조회 (게스트 허용) */
    @Operation(summary = "게시글 상세 조회", description = "조회 시 viewCount 1 증가. 블라인드 게시글은 내용을 가려서 반환.")
    @GetMapping("/{postId}")
    public ResponseEntity<ApiResponse<PostDetailResponse>> getPostDetail(
            @PathVariable Long postId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserIdNullable(authentication);
        return ResponseEntity.ok(ApiResponse.success(
                communityPostService.getPostDetail(postId, userId)));
    }

    /** HX_COM_004 — 게시글 수정 */
    @Operation(summary = "게시글 수정",
            description = "본인 게시글만 수정 가능. 유지할 기존 이미지 URL(keepImageUrls)과 새로 업로드할 이미지(newImages)로 부분 갱신합니다. " +
                    "기존 이미지 중 keepImageUrls에 포함되지 않은 URL은 S3·DB에서 삭제됩니다. 총 이미지 수 최대 5장. JWT 필요.")
    @PutMapping(value = "/{postId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<Void>> updatePost(
            @PathVariable Long postId,
            @RequestPart("title") String title,
            @RequestPart("content") String content,
            @RequestParam(value = "keepImageUrls", required = false) List<String> keepImageUrls,
            @RequestPart(value = "newImages", required = false) List<MultipartFile> newImages,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        communityPostService.updatePost(userId, postId, title, content, keepImageUrls, newImages);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /** HX_COM_005 — 게시글 삭제 */
    @Operation(summary = "게시글 삭제", description = "본인 게시글만 삭제. 이미지·댓글·좋아요·북마크 cascade 삭제. JWT 필요.")
    @DeleteMapping("/{postId}")
    public ResponseEntity<ApiResponse<Void>> deletePost(
            @PathVariable Long postId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        communityPostService.deletePost(userId, postId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }

    /** COM-011 — 게시글 번역 (게스트 허용) */
    @Operation(summary = "게시글 번역", description = "게시글 제목·본문을 지정 언어로 번역합니다. lang: ko|en|zh|vi|th|ja. 인증 불필요.")
    @GetMapping("/{postId}/translate")
    public ResponseEntity<ApiResponse<PostTranslationResponse>> translatePost(
            @PathVariable Long postId,
            @RequestParam
            @Pattern(regexp = "^(ko|en|zh|vi|th|ja)$", message = "지원하지 않는 언어 코드입니다.")
            String lang) {
        return ResponseEntity.ok(ApiResponse.success(communityPostService.translatePost(postId, lang)));
    }
}
