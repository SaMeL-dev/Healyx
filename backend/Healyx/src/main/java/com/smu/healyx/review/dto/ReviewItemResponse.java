package com.smu.healyx.review.dto;

import com.smu.healyx.review.domain.Review;
import com.smu.healyx.review.domain.ReviewImage;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class ReviewItemResponse {

    private Long reviewId;

    /** 닉네임 마스킹: 앞 2자 + "***" */
    private String nickname;

    private int rating;
    private String content;
    private List<String> images;
    private LocalDateTime createdAt;

    public static ReviewItemResponse of(Review review, List<ReviewImage> reviewImages) {
        String nickname = review.getUser().getNickname();
        String masked = nickname.length() > 2
                ? nickname.substring(0, 2) + "***"
                : nickname.charAt(0) + "***";

        return ReviewItemResponse.builder()
                .reviewId(review.getReviewId())
                .nickname(masked)
                .rating(review.getRating())
                .content(review.getContent())
                .images(reviewImages.stream().map(ReviewImage::getImageUrl).toList())
                .createdAt(review.getCreatedAt())
                .build();
    }
}
