package com.smu.healyx.review.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class HospitalReviewResponse {

    /** 전체 리뷰 기준 평균 별점 (소수점 1자리) */
    private double averageRating;

    /** 전체 리뷰 수 */
    private long totalCount;

    /** 현재 페이지 리뷰 목록 */
    private List<ReviewItemResponse> reviews;
}
