package com.smu.healyx.review.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.web.multipart.MultipartFile;

@Getter
@Setter
@NoArgsConstructor
public class OcrVerifyRequest {

    /** 영수증 이미지 파일 */
    private MultipartFile receiptImage;

    /** 사용자가 선택한 병원의 ykiho — hospitals 테이블 조회 키 */
    private String ykiho;
}
