package com.smu.healyx.review.dto;

import com.smu.healyx.review.domain.Review;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

/** 메인화면 최신 리뷰 미리보기 항목 */
@Getter
@Builder
public class LatestReviewItem {

    private Long reviewId;
    private String hospitalName;

    /** 닉네임 마스킹: 앞 2자 + "***" */
    private String nickname;

    private String content;
    private int rating;
    private LocalDateTime createdAt;

    public static LatestReviewItem of(Review review) {
        String nickname = review.getUser().getNickname();
        String masked = nickname.length() > 2
                ? nickname.substring(0, 2) + "***"
                : nickname.charAt(0) + "***";

        return LatestReviewItem.builder()
                .reviewId(review.getReviewId())
                .hospitalName(review.getHospital().getName())
                .nickname(masked)
                .content(review.getContent())
                .rating(review.getRating())
                .createdAt(review.getCreatedAt())
                .build();
    }
}
