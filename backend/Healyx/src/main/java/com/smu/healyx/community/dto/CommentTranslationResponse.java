package com.smu.healyx.community.dto;

import lombok.Builder;
import lombok.Getter;

/**
 * 댓글 번역 응답 DTO (COM-011).
 * 번역된 댓글 내용과 원문을 함께 반환하여 Flutter가 "원문 보기" 토글 가능하도록 함.
 */
@Getter
@Builder
public class CommentTranslationResponse {

    private Long commentId;
    private String lang;
    private String translatedContent;
    /** 소프트 삭제된 댓글인 경우 null 반환 */
    private String originalContent;
}
