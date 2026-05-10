package com.smu.healyx.review.dto;

import com.smu.healyx.review.domain.Review;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class MyReviewResponse {

    private Long reviewId;
    private String hospitalName;    // 병원 이름
    private String contentPreview;  // 후기 최대 20자, 초과 시 "..." 처리
    private int rating;             // 별점
    private LocalDateTime createdAt;

    public static MyReviewResponse from(Review review) {
        return MyReviewResponse.builder()
                .reviewId(review.getReviewId())
                .hospitalName(review.getHospital().getName())
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
