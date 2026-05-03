package com.smu.healyx.translation.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TextBlock {
    private String originalText;
    private String translatedText;
    private int x;
    private int y;
    private int width;
    private int height;
}
