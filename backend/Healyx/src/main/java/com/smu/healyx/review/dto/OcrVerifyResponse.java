package com.smu.healyx.review.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class OcrVerifyResponse {

    /** S3에 저장된 영수증 이미지 URL — 리뷰 등록 시 receipt_image_url로 사용 */
    private String receiptImageUrl;
}
