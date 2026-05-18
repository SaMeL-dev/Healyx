package com.smu.healyx.community.dto;

import lombok.Builder;
import lombok.Getter;

/**
 * 게시글 번역 응답 DTO (COM-011).
 * 번역된 제목·본문과 원문을 함께 반환하여 Flutter가 "원문 보기" 토글 가능하도록 함.
 */
@Getter
@Builder
public class PostTranslationResponse {

    private Long postId;
    private String lang;
    private String translatedTitle;
    private String translatedContent;
    private String originalTitle;
    /** 블라인드 게시글인 경우 null 반환 */
    private String originalContent;
}
