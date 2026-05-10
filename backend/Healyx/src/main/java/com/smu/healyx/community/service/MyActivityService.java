package com.smu.healyx.community.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.service.S3UploadService;
import com.smu.healyx.community.domain.CommunityComment;
import com.smu.healyx.community.domain.CommunityPost;
import com.smu.healyx.community.domain.PostImage;
import com.smu.healyx.community.dto.MyCommentResponse;
import com.smu.healyx.community.dto.MyPostResponse;
import com.smu.healyx.community.repository.CommunityCommentRepository;
import com.smu.healyx.community.repository.CommunityPostRepository;
import com.smu.healyx.community.repository.PostImageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class MyActivityService {

    private final CommunityPostRepository communityPostRepository;
    private final CommunityCommentRepository communityCommentRepository;
    private final PostImageRepository postImageRepository;
    private final S3UploadService s3UploadService;

    /** 내가 쓴 게시글 목록 — 최신순 */
    @Transactional(readOnly = true)
    public List<MyPostResponse> getMyPosts(Long userId) {
        return communityPostRepository.findByUser_UserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(MyPostResponse::from)
                .toList();
    }

    /** 내 게시글 삭제 — S3 이미지 먼저 삭제 후 DB 삭제 (cascade로 post_images 함께 제거) */
    @Transactional
    public void deleteMyPost(Long userId, Long postId) {
        CommunityPost post = communityPostRepository.findById(postId)
                .orElseThrow(() -> new AuthException("POST_NOT_FOUND", "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        if (!post.getUser().getUserId().equals(userId)) {
            throw new AuthException("ACCESS_DENIED", "해당 게시글을 삭제할 권한이 없습니다.", HttpStatus.FORBIDDEN);
        }

        // 첨부 이미지 S3 삭제
        List<PostImage> images = postImageRepository.findByPost_PostIdOrderBySortOrderAsc(postId);
        images.forEach(img -> deleteS3ImageQuietly(img.getImageUrl()));

        // DB 삭제 — CommunityPost cascade로 comments·bookmarks·likes·postImages 함께 삭제
        communityPostRepository.delete(post);
    }

    /** 내 댓글 삭제 — 대댓글 먼저 삭제 후 하드 삭제 */
    @Transactional
    public void deleteMyComment(Long userId, Long commentId) {
        CommunityComment comment = communityCommentRepository.findById(commentId)
                .orElseThrow(() -> new AuthException("COMMENT_NOT_FOUND", "댓글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        if (!comment.getUser().getUserId().equals(userId)) {
            throw new AuthException("ACCESS_DENIED", "해당 댓글을 삭제할 권한이 없습니다.", HttpStatus.FORBIDDEN);
        }

        // FK 제약 오류 방지: 대댓글 먼저 삭제
        communityCommentRepository.deleteByParentComment_CommentId(commentId);
        communityCommentRepository.delete(comment);
    }

    /** 내가 쓴 댓글 목록 — 삭제 제외, 최신순 */
    @Transactional(readOnly = true)
    public List<MyCommentResponse> getMyComments(Long userId) {
        return communityCommentRepository.findMyCommentsWithPost(userId)
                .stream()
                .map(MyCommentResponse::from)
                .toList();
    }

    private void deleteS3ImageQuietly(String imageUrl) {
        if (imageUrl == null || imageUrl.isBlank()) return;
        try {
            s3UploadService.delete(imageUrl);
        } catch (Exception e) {
            log.warn("S3 이미지 삭제 실패 (무시됨): url={}", imageUrl, e);
        }
    }
}
