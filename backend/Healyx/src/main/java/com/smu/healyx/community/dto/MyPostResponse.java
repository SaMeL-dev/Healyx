package com.smu.healyx.community.dto;

import com.smu.healyx.community.domain.CommunityPost;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class MyPostResponse {

    private Long postId;
    private String title;
    private String contentPreview;  // 최대 20자, 초과 시 "..." 처리
    private int likeCount;
    private LocalDateTime createdAt;

    public static MyPostResponse from(CommunityPost post) {
        return MyPostResponse.builder()
                .postId(post.getPostId())
                .title(post.getTitle())
                .contentPreview(preview(post.getContent()))
                .likeCount(post.getLikeCount())
                .createdAt(post.getCreatedAt())
                .build();
    }

    private static String preview(String content) {
        if (content == null) return "";
        return content.length() <= 20 ? content : content.substring(0, 20) + "...";
    }
}
