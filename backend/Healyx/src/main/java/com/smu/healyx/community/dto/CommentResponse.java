package com.smu.healyx.community.dto;

import com.smu.healyx.community.domain.CommunityComment;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class CommentResponse {

    private Long commentId;
    private Long authorId;
    private String authorNickname;
    private String content;
    private int depth;
    private boolean isDeleted;
    private Long parentCommentId;
    private Long mentionUserId;
    private LocalDateTime createdAt;
    private List<CommentResponse> replies;  // depth=0만 replies 포함, depth=1은 항상 빈 리스트

    public static CommentResponse from(CommunityComment comment) {
        List<CommentResponse> replies = comment.getChildComments().stream()
                .map(CommentResponse::from)
                .toList();

        return CommentResponse.builder()
                .commentId(comment.getCommentId())
                .authorId(comment.getUser().getUserId())
                .authorNickname(comment.isDeleted() ? null : comment.getUser().getNickname())
                .content(comment.getContent())
                .depth(comment.getDepth())
                .isDeleted(comment.isDeleted())
                .parentCommentId(comment.getParentComment() != null ? comment.getParentComment().getCommentId() : null)
                .mentionUserId(comment.getMentionUser() != null ? comment.getMentionUser().getUserId() : null)
                .createdAt(comment.getCreatedAt())
                .replies(replies)
                .build();
    }
}
