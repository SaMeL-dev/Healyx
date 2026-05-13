package com.smu.healyx.community.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class PostDetailResponse {

    private Long postId;
    private Long authorId;
    private String authorNickname;
    private String title;
    private String content;
    private boolean isBlinded;
    private int likeCount;
    private int viewCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<String> imageUrls;
    private boolean myLikeExists;     // PR-3에서 채워짐, 현재는 항상 false
    private boolean myBookmarkExists; // PR-3에서 채워짐, 현재는 항상 false
}
