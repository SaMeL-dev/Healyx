package com.smu.healyx.review.dto;

import lombok.Builder;
import lombok.Getter;

/**
 * 리뷰 전용 병원 검색(UI-REV-02) 응답 카드 단건.
 * 화면 카드 구성: 이름 / 주소 / 평균 별점 / 리뷰 수
 */
@Getter
@Builder
public class ReviewHospitalItem {

    /** 암호화된 요양기호 — 후속 OCR 인증·리뷰 등록의 키 */
    private final String ykiho;

    /** 병원명 */
    private final String name;

    /** 병원 주소 */
    private final String address;

    /** 평균 별점 (소수점 1자리, 리뷰 0건이면 0.0) */
    private final double averageRating;

    /** 누적 리뷰 수 (리뷰 0건이면 0) */
    private final int reviewCount;
}
