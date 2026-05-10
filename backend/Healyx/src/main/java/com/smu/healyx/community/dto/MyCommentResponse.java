package com.smu.healyx.community.dto;

import com.smu.healyx.community.domain.CommunityComment;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class MyCommentResponse {

    private Long commentId;
    private Long postId;        // 댓글이 달린 게시글 ID
    private String postTitle;   // 댓글이 달린 게시글 제목
    private String content;
    private LocalDateTime createdAt;

    public static MyCommentResponse from(CommunityComment comment) {
        return MyCommentResponse.builder()
                .commentId(comment.getCommentId())
                .postId(comment.getPost().getPostId())
                .postTitle(comment.getPost().getTitle())
                .content(comment.getContent())
                .createdAt(comment.getCreatedAt())
                .build();
    }
}
