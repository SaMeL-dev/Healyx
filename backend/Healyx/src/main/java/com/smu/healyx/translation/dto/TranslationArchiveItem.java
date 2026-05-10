package com.smu.healyx.translation.dto;

import com.smu.healyx.translation.domain.MedicalTranslation;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class TranslationArchiveItem {

    private Long translationId;
    private String imageUrl;            // 원본 사진 S3 URL
    private String translatedImageUrl;  // 번역 사진 S3 URL
    private LocalDateTime createdAt;    // 저장 날짜
    private String targetLanguage;      // 번역 언어

    public static TranslationArchiveItem from(MedicalTranslation entity) {
        return TranslationArchiveItem.builder()
                .translationId(entity.getTranslationId())
                .imageUrl(entity.getImageUrl())
                .translatedImageUrl(entity.getTranslatedImageUrl())
                .createdAt(entity.getCreatedAt())
                .targetLanguage(entity.getTargetLanguage())
                .build();
    }
}
