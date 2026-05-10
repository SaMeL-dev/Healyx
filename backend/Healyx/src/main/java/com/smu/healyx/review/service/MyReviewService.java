package com.smu.healyx.review.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.review.domain.Review;
import com.smu.healyx.review.dto.MyReviewResponse;
import com.smu.healyx.review.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MyReviewService {

    private final ReviewRepository reviewRepository;

    /** 내 리뷰 목록 조회 — 최신순 */
    @Transactional(readOnly = true)
    public List<MyReviewResponse> getMyReviews(Long userId) {
        return reviewRepository.findMyReviewsWithHospital(userId)
                .stream()
                .map(MyReviewResponse::from)
                .toList();
    }

    /** 내 리뷰 삭제 — 본인 소유 확인 후 하드 삭제 */
    @Transactional
    public void deleteMyReview(Long userId, Long reviewId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new AuthException("REVIEW_NOT_FOUND", "리뷰를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        if (!review.getUser().getUserId().equals(userId)) {
            throw new AuthException("ACCESS_DENIED", "해당 리뷰를 삭제할 권한이 없습니다.", HttpStatus.FORBIDDEN);
        }

        reviewRepository.delete(review);
    }
}
