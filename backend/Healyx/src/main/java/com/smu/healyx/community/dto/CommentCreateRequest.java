package com.smu.healyx.community.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class CommentCreateRequest {

    @NotBlank
    @Size(max = 500)
    private String content;

    @Positive
    private Long parentCommentId;  // null이면 depth=0 댓글, 있으면 대댓글

    @Positive
    private Long mentionUserId;    // optional
}
