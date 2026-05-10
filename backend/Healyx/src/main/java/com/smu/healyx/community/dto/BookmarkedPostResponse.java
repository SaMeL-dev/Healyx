package com.smu.healyx.community.dto;

import com.smu.healyx.community.domain.CommunityBookmark;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class BookmarkedPostResponse {

    private Long postId;
    private String title;
    private String author;          // 작성자 닉네임
    private String contentPreview;  // 내용 최대 20자, 초과 시 "..." 처리
    private int likeCount;

    public static BookmarkedPostResponse from(CommunityBookmark bookmark) {
        return BookmarkedPostResponse.builder()
                .postId(bookmark.getPost().getPostId())
                .title(bookmark.getPost().getTitle())
                .author(bookmark.getPost().getUser().getNickname())
                .contentPreview(preview(bookmark.getPost().getContent()))
                .likeCount(bookmark.getPost().getLikeCount())
                .build();
    }

    private static String preview(String content) {
        if (content == null) return "";
        return content.length() <= 20 ? content : content.substring(0, 20) + "...";
    }
}
