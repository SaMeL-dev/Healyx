package com.smu.healyx.community.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.service.S3UploadService;
import com.smu.healyx.community.domain.CommunityPost;
import com.smu.healyx.community.domain.PostImage;
import com.smu.healyx.community.dto.PostDetailResponse;
import com.smu.healyx.community.dto.PostListItemResponse;
import com.smu.healyx.community.repository.CommunityCommentRepository;
import com.smu.healyx.community.repository.CommunityPostRepository;
import com.smu.healyx.community.repository.PostImageRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class CommunityPostService {

    private final CommunityPostRepository postRepository;
    private final PostImageRepository postImageRepository;
    private final CommunityCommentRepository commentRepository;
    private final UserRepository userRepository;
    private final S3UploadService s3UploadService;
    private final CommunityCommentService communityCommentService;

    /** HX_COM_002 — 게시글 등록 */
    @Transactional
    public Long createPost(Long userId, String title, String content, List<MultipartFile> images) {
        if (images != null && images.size() > 5) {
            throw new AuthException("TOO_MANY_IMAGES", "이미지는 최대 5장까지 첨부할 수 있습니다.", HttpStatus.BAD_REQUEST);
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND", "사용자 정보를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        CommunityPost post = CommunityPost.builder()
                .user(user)
                .title(title)
                .content(content)
                .build();

        postRepository.save(post);

        if (images != null) {
            List<PostImage> postImages = new ArrayList<>();
            for (int i = 0; i < images.size(); i++) {
                MultipartFile file = images.get(i);
                try {
                    String url = s3UploadService.upload(file.getBytes(), "community/posts", file.getContentType());
                    postImages.add(PostImage.builder()
                            .post(post).imageUrl(url).sortOrder(i).build());
                } catch (IOException e) {
                    throw new RuntimeException("이미지 업로드 중 오류가 발생했습니다.", e);
                }
            }
            postImageRepository.saveAll(postImages);
        }

        return post.getPostId();
    }

    /** HX_COM_008 — 게시글 목록·검색 (keyword=null 이면 전체 목록) */
    @Transactional(readOnly = true)
    public Page<PostListItemResponse> searchPosts(String keyword, String searchField, String sort, int page, int size) {
        String kw = (keyword == null || keyword.isBlank()) ? "" : keyword.trim();
        String sf = (searchField == null || searchField.isBlank()) ? "all" : searchField;

        Sort sortOrder = "popular".equals(sort)
                ? Sort.by(Sort.Direction.DESC, "likeCount")
                : Sort.by(Sort.Direction.DESC, "createdAt");

        Pageable pageable = PageRequest.of(page, size, sortOrder);
        Page<CommunityPost> posts = postRepository.searchPosts(kw, sf, pageable);

        return posts.map(p -> {
            long cnt = commentRepository.countByPost_PostIdAndIsDeletedFalse(p.getPostId());
            return PostListItemResponse.of(p, cnt);
        });
    }

    /** HX_COM_015 — 게시글 상세 조회 */
    @Transactional
    public PostDetailResponse getPostDetail(Long postId, Long userId) {
        CommunityPost post = postRepository.findById(postId)
                .orElseThrow(() -> new AuthException("POST_NOT_FOUND", "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        postRepository.incrementViewCount(postId);

        List<String> imageUrls = postImageRepository.findByPost_PostIdOrderBySortOrderAsc(postId)
                .stream().map(PostImage::getImageUrl).toList();

        String displayContent = post.isBlinded()
                ? "신고로 가려진 게시물입니다."
                : post.getContent();

        return PostDetailResponse.builder()
                .postId(post.getPostId())
                .authorId(post.getUser().getUserId())
                .authorNickname(post.getUser().getNickname())
                .title(post.getTitle())
                .content(displayContent)
                .isBlinded(post.isBlinded())
                .likeCount(post.getLikeCount())
                .viewCount(post.getViewCount() + 1)
                .createdAt(post.getCreatedAt())
                .updatedAt(post.getUpdatedAt())
                .imageUrls(imageUrls)
                .myLikeExists(false)
                .myBookmarkExists(false)
                .comments(communityCommentService.getCommentsByPost(postId))
                .build();
    }

    /** HX_COM_004 — 게시글 수정 */
    @Transactional
    public void updatePost(Long userId, Long postId, String title, String content, List<MultipartFile> images) {
        CommunityPost post = postRepository.findById(postId)
                .orElseThrow(() -> new AuthException("POST_NOT_FOUND", "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        if (!post.getUser().getUserId().equals(userId)) {
            throw new AuthException("FORBIDDEN", "해당 게시글을 수정할 권한이 없습니다.", HttpStatus.FORBIDDEN);
        }

        if (images != null && images.size() > 5) {
            throw new AuthException("TOO_MANY_IMAGES", "이미지는 최대 5장까지 첨부할 수 있습니다.", HttpStatus.BAD_REQUEST);
        }

        // 기존 이미지 S3 삭제 후 DB 삭제
        List<PostImage> existingImages = postImageRepository.findByPost_PostIdOrderBySortOrderAsc(postId);
        existingImages.forEach(img -> deleteS3Quietly(img.getImageUrl()));
        postImageRepository.deleteAll(existingImages);

        // 새 이미지 업로드
        if (images != null && !images.isEmpty()) {
            List<PostImage> newImages = new ArrayList<>();
            for (int i = 0; i < images.size(); i++) {
                MultipartFile file = images.get(i);
                try {
                    String url = s3UploadService.upload(file.getBytes(), "community/posts", file.getContentType());
                    newImages.add(PostImage.builder()
                            .post(post).imageUrl(url).sortOrder(i).build());
                } catch (IOException e) {
                    throw new RuntimeException("이미지 업로드 중 오류가 발생했습니다.", e);
                }
            }
            postImageRepository.saveAll(newImages);
        }

        post.updateTitleAndContent(title, content);
    }

    /** HX_COM_005 — 게시글 삭제 */
    @Transactional
    public void deletePost(Long userId, Long postId) {
        CommunityPost post = postRepository.findById(postId)
                .orElseThrow(() -> new AuthException("POST_NOT_FOUND", "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        if (!post.getUser().getUserId().equals(userId)) {
            throw new AuthException("FORBIDDEN", "해당 게시글을 삭제할 권한이 없습니다.", HttpStatus.FORBIDDEN);
        }

        List<PostImage> images = postImageRepository.findByPost_PostIdOrderBySortOrderAsc(postId);
        images.forEach(img -> deleteS3Quietly(img.getImageUrl()));

        postRepository.delete(post);
    }

    private void deleteS3Quietly(String imageUrl) {
        if (imageUrl == null || imageUrl.isBlank()) return;
        try {
            s3UploadService.delete(imageUrl);
        } catch (Exception e) {
            log.warn("S3 이미지 삭제 실패 (무시됨): url={}", imageUrl, e);
        }
    }
}
