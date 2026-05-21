package com.smu.healyx.community.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.community.domain.CommunityComment;
import com.smu.healyx.community.domain.CommunityPost;
import com.smu.healyx.community.dto.CommentCreateRequest;
import com.smu.healyx.community.dto.CommentResponse;
import com.smu.healyx.community.dto.CommentTranslationResponse;
import com.smu.healyx.community.dto.CommentUpdateRequest;
import com.smu.healyx.community.repository.CommunityCommentRepository;
import com.smu.healyx.community.repository.CommunityPostRepository;
import com.smu.healyx.deepl.service.TranslationService;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class CommunityCommentService {

    private final CommunityCommentRepository commentRepository;
    private final CommunityPostRepository postRepository;
    private final UserRepository userRepository;
    private final ContentFilterService contentFilterService;
    private final NotificationService notificationService;
    private final TranslationService translationService;
    private final MessageSource messageSource;

    /** HX_COM_006 — 댓글·대댓글 등록 */
    @Transactional
    public Long createComment(Long userId, Long postId, CommentCreateRequest req) {
        if (req.getContent().length() > 500) {
            throw new AuthException("CONTENT_TOO_LONG", "댓글은 최대 500자까지 작성할 수 있습니다.", HttpStatus.BAD_REQUEST);
        }

        contentFilterService.filterWithLLM(null, req.getContent());

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND", "사용자 정보를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        CommunityPost post = postRepository.findById(postId)
                .orElseThrow(() -> new AuthException("POST_NOT_FOUND", "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        CommunityComment parentComment = null;
        int depth = 0;

        if (req.getParentCommentId() != null) {
            parentComment = commentRepository.findById(req.getParentCommentId())
                    .orElseThrow(() -> new AuthException("COMMENT_NOT_FOUND", "부모 댓글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));
            if (parentComment.getDepth() >= 1) {
                throw new AuthException("MAX_DEPTH_EXCEEDED", "대댓글에는 대댓글을 달 수 없습니다.", HttpStatus.BAD_REQUEST);
            }
            depth = 1;
        }

        User mentionUser = null;
        if (req.getMentionUserId() != null) {
            mentionUser = userRepository.findById(req.getMentionUserId()).orElse(null);
        }

        CommunityComment comment = CommunityComment.builder()
                .post(post)
                .user(user)
                .parentComment(parentComment)
                .mentionUser(mentionUser)
                .depth(depth)
                .content(req.getContent())
                .build();

        Long commentId = commentRepository.save(comment).getCommentId();

        // FCM 알림 (본인 활동 제외)
        if (depth == 0) {
            Long postAuthorId = post.getUser().getUserId();
            if (!postAuthorId.equals(userId)) {
                notificationService.sendPushNotification(postAuthorId, "COMMENT", commentId, post.getPostId());
            }
        } else {
            Long parentAuthorId = parentComment.getUser().getUserId();
            if (!parentAuthorId.equals(userId)) {
                notificationService.sendPushNotification(parentAuthorId, "REPLY", commentId, post.getPostId());
            }
        }

        return commentId;
    }

    /** 댓글 수정 — 본인 댓글 content만 변경 가능 */
    @Transactional
    public void updateComment(Long userId, Long commentId, CommentUpdateRequest req) {
        CommunityComment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new AuthException("COMMENT_NOT_FOUND", "댓글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        if (!comment.getUser().getUserId().equals(userId)) {
            throw new AuthException("FORBIDDEN", "해당 댓글을 수정할 권한이 없습니다.", HttpStatus.FORBIDDEN);
        }

        if (comment.isDeleted()) {
            throw new AuthException("COMMENT_ALREADY_DELETED", "이미 삭제된 댓글은 수정할 수 없습니다.", HttpStatus.BAD_REQUEST);
        }

        contentFilterService.filterWithLLM(null, req.getContent());
        comment.updateContent(req.getContent());
    }

    /** HX_COM_007 — 댓글 삭제 (soft/hard 조건 분기) */
    @Transactional
    public void deleteComment(Long userId, Long commentId) {
        CommunityComment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new AuthException("COMMENT_NOT_FOUND", "댓글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        if (!comment.getUser().getUserId().equals(userId)) {
            throw new AuthException("FORBIDDEN", "해당 댓글을 삭제할 권한이 없습니다.", HttpStatus.FORBIDDEN);
        }

        boolean hasActiveReplies = !commentRepository
                .findByParentComment_CommentIdAndIsDeletedFalse(commentId).isEmpty();

        if (hasActiveReplies) {
            String deletedMsg = messageSource.getMessage("comment.deleted", null, LocaleContextHolder.getLocale());
            comment.softDelete(deletedMsg);
        } else {
            commentRepository.delete(comment);
        }
    }

    /** COM-011 — 댓글 번역 (게스트 허용) */
    @Transactional(readOnly = true)
    public CommentTranslationResponse translateComment(Long commentId, String lang) {
        CommunityComment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new AuthException("COMMENT_NOT_FOUND", "댓글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        String translatedContent;

        if (comment.isDeleted()) {
            translatedContent = messageSource.getMessage("comment.deleted", null, LocaleContextHolder.getLocale());
        } else {
            translatedContent = translationService.translate(comment.getContent(), lang).getTranslatedText();
        }

        return CommentTranslationResponse.builder()
                .commentId(comment.getCommentId())
                .lang(lang)
                .translatedContent(translatedContent)
                .originalContent(comment.isDeleted() ? null : comment.getContent())
                .build();
    }

    /** getCommentsByPost — PostDetailResponse 댓글 목록 조회용 (N+1 방지 JOIN FETCH) */
    @Transactional(readOnly = true)
    public List<CommentResponse> getCommentsByPost(Long postId) {
        return commentRepository.findTopLevelCommentsByPostId(postId).stream()
                .map(CommentResponse::from)
                .toList();
    }
}
