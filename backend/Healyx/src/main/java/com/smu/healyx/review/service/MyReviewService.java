package com.smu.healyx.review.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.service.S3UploadService;
import com.smu.healyx.review.domain.Review;
import com.smu.healyx.review.domain.ReviewImage;
import com.smu.healyx.review.dto.MyReviewResponse;
import com.smu.healyx.review.repository.ReviewImageRepository;
import com.smu.healyx.review.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class MyReviewService {

    private final ReviewRepository reviewRepository;
    private final ReviewImageRepository reviewImageRepository;
    private final S3UploadService s3UploadService;

    /** 내 리뷰 목록 조회 — 최신순 */
    @Transactional(readOnly = true)
    public List<MyReviewResponse> getMyReviews(Long userId) {
        return reviewRepository.findMyReviewsWithHospital(userId)
                .stream()
                .map(MyReviewResponse::from)
                .toList();
    }

    /** 내 리뷰 삭제 — S3 이미지 먼저 삭제 후 DB 삭제 (cascade로 review_images 함께 제거) */
    @Transactional
    public void deleteMyReview(Long userId, Long reviewId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new AuthException("REVIEW_NOT_FOUND", "리뷰를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        if (!review.getUser().getUserId().equals(userId)) {
            throw new AuthException("ACCESS_DENIED", "해당 리뷰를 삭제할 권한이 없습니다.", HttpStatus.FORBIDDEN);
        }

        // 첨부 이미지 S3 삭제
        List<ReviewImage> images = reviewImageRepository.findByReview_ReviewIdOrderBySortOrderAsc(reviewId);
        images.forEach(img -> deleteS3ImageQuietly(img.getImageUrl()));

        // 영수증 이미지 S3 삭제
        deleteS3ImageQuietly(review.getReceiptImageUrl());

        // DB 삭제 — Review.reviewImages에 CascadeType.REMOVE 적용으로 review_images 함께 삭제
        reviewRepository.delete(review);
    }

    private void deleteS3ImageQuietly(String imageUrl) {
        if (imageUrl == null || imageUrl.isBlank()) return;
        try {
            s3UploadService.delete(imageUrl);
        } catch (Exception e) {
            log.warn("S3 이미지 삭제 실패 (무시됨): url={}", imageUrl, e);
        }
    }
}
