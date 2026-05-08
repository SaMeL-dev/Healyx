package com.smu.healyx.review.dto;

import com.smu.healyx.review.domain.Review;
import com.smu.healyx.review.domain.ReviewImage;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Builder
public class MyReviewResponse {

    private Long reviewId;
    private String hospitalName;
    private int rating;
    private String content;
    private List<String> images;
    private LocalDateTime createdAt;

    public static MyReviewResponse of(Review review, List<ReviewImage> reviewImages) {
        return MyReviewResponse.builder()
                .reviewId(review.getReviewId())
                .hospitalName(review.getHospital().getName())
                .rating(review.getRating())
                .content(review.getContent())
                .images(reviewImages.stream().map(ReviewImage::getImageUrl).toList())
                .createdAt(review.getCreatedAt())
                .build();
    }
}
