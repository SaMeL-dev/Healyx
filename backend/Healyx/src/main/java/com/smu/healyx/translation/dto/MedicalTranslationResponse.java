package com.smu.healyx.translation.dto;

import com.smu.healyx.translation.domain.MedicalTranslation;
import lombok.Builder;
import lombok.Getter;

import java.util.Base64;

@Getter
@Builder
public class MedicalTranslationResponse {

    private Long translationId;          // 로그인 사용자만 존재
    private String originalText;
    private String translatedText;
    private String imageUrl;             // 로그인: S3 원본 이미지 URL
    private String translatedImageUrl;   // 로그인: S3 오버레이 이미지 URL
    private String translatedImageBase64; // 게스트: 오버레이 이미지 Base64

    /** 로그인 사용자 응답 (DB 저장 결과 기반) */
    public static MedicalTranslationResponse fromEntity(MedicalTranslation entity) {
        return MedicalTranslationResponse.builder()
                .translationId(entity.getTranslationId())
                .originalText(entity.getOriginalText())
                .translatedText(entity.getTranslatedText())
                .imageUrl(entity.getImageUrl())
                .translatedImageUrl(entity.getTranslatedImageUrl())
                .build();
    }

    /** 게스트 응답 (S3/DB 저장 없이 Base64로 반환) */
    public static MedicalTranslationResponse forGuest(String originalText, String translatedText, byte[] overlayBytes) {
        return MedicalTranslationResponse.builder()
                .originalText(originalText)
                .translatedText(translatedText)
                .translatedImageBase64(Base64.getEncoder().encodeToString(overlayBytes))
                .build();
    }
}
