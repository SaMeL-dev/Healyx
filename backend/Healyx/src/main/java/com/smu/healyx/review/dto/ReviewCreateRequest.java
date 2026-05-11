package com.smu.healyx.review.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class ReviewCreateRequest {

    /** 리뷰 대상 병원 ykiho */
    private String ykiho;

    /** 별점 1~5 */
    private int rating;

    /** 리뷰 본문 (선택, 최대 2000자) */
    private String content;

    /** 첨부 이미지 (선택, 최대 5장) */
    private List<MultipartFile> images;
}
