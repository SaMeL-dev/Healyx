package com.smu.healyx.community.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class ToggleLikeResponse {
    private boolean liked;
    private int likeCount;
}
