package com.smu.healyx.review.dto;

import com.smu.healyx.review.domain.Review;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class MyReviewResponse {

    private Long reviewId;
    private String ykiho;           // 병원 요양기호 — 상세 화면 이동에 필요
    private String hospitalName;
    private String address;
    private boolean foreignCertified;
    private String contentPreview;  // 후기 최대 20자, 초과 시 "..." 처리
    private int rating;
    private LocalDateTime createdAt;

    public static MyReviewResponse from(Review review) {
        return MyReviewResponse.builder()
                .reviewId(review.getReviewId())
                .ykiho(review.getHospital().getYkiho())
                .hospitalName(review.getHospital().getName())
                .address(review.getHospital().getAddress())
                .foreignCertified(review.getHospital().isForeignCertified())
                .contentPreview(preview(review.getContent()))
                .rating(review.getRating())
                .createdAt(review.getCreatedAt())
                .build();
    }

    private static String preview(String content) {
        if (content == null) return "";
        return content.length() <= 20 ? content : content.substring(0, 20) + "...";
    }
}