package com.smu.healyx.community.dto;

import com.smu.healyx.community.domain.CommunityPost;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class PostListItemResponse {

    private Long postId;
    private String title;
    private String contentPreview;
    private String authorNickname;
    private int likeCount;
    private long commentCount;
    private LocalDateTime createdAt;

    public static PostListItemResponse of(CommunityPost post, long commentCount) {
        String raw = post.getContent();
        String preview = (raw != null && raw.length() > 100) ? raw.substring(0, 100) + "..." : raw;
        return PostListItemResponse.builder()
                .postId(post.getPostId())
                .title(post.getTitle())
                .contentPreview(preview)
                .authorNickname(post.getUser().getNickname())
                .likeCount(post.getLikeCount())
                .commentCount(commentCount)
                .createdAt(post.getCreatedAt())
                .build();
    }
}
