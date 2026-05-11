package com.smu.healyx.review.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

/**
 * 리뷰 전용 병원 검색(UI-REV-01, UI-REV-02) API 응답.
 */
@Getter
@Builder
public class ReviewHospitalSearchResponse {

    /** 응답 결과 총 건수 (region 필터 적용 후 기준) */
    private final int totalCount;

    /** 검색된 병원 카드 리스트 */
    private final List<ReviewHospitalItem> hospitals;
}
