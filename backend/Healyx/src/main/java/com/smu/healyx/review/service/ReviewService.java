package com.smu.healyx.review.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.service.S3UploadService;
import com.smu.healyx.hospital.domain.Hospital;
import com.smu.healyx.hospital.repository.HospitalRepository;
import com.smu.healyx.review.domain.Review;
import com.smu.healyx.review.domain.ReviewImage;
import com.smu.healyx.review.dto.*;
import com.smu.healyx.review.repository.ReviewImageRepository;
import com.smu.healyx.review.repository.ReviewRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final ReviewImageRepository reviewImageRepository;
    private final HospitalRepository hospitalRepository;
    private final UserRepository userRepository;
    private final OcrVerificationService ocrVerificationService;
    private final S3UploadService s3UploadService;

    private static final int MAX_IMAGES = 5;
    private static final int MAX_CONTENT_LENGTH = 2000;

    // ── 리뷰 등록 (RV-005~007) ───────────────────────────────────────

    /**
     * OCR 인증 토큰 검증 후 리뷰를 등록한다.
     *
     * @return 생성된 reviewId
     */
    @Transactional
    public Long create(Long userId, ReviewCreateRequest request) throws IOException {

        // 1. OCR 인증 상태 확인 (Redis key 존재 여부)
        String receiptImageUrl = ocrVerificationService.getReceiptImageUrl(userId, request.getYkiho());
        if (receiptImageUrl == null) {
            throw new AuthException(
                    "OCR_TOKEN_EXPIRED",
                    "인증이 만료되었습니다. 영수증을 다시 인증해 주세요.",
                    HttpStatus.BAD_REQUEST);
        }

        // 2. 입력값 유효성 검사
        validateCreateRequest(request);


        // 3. 연관 엔티티 조회
        Hospital hospital = hospitalRepository.findByYkiho(request.getYkiho())
                .orElseThrow(() -> new AuthException(
                        "HOSPITAL_NOT_FOUND",
                        "병원 정보를 찾을 수 없습니다.",
                        HttpStatus.NOT_FOUND));

        // 중복 리뷰 방지
        if (reviewRepository.existsByUser_UserIdAndHospital_HospitalId(userId, hospital.getHospitalId())) {
            throw new AuthException(
                    "REVIEW_ALREADY_EXISTS",
                    "이미 해당 병원에 리뷰를 작성했습니다.",
                    HttpStatus.CONFLICT);
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthException(
                        "USER_NOT_FOUND",
                        "사용자 정보를 찾을 수 없습니다.",
                        HttpStatus.NOT_FOUND));

        // 4. 리뷰 이미지 S3 업로드
        List<String> imageUrls = uploadImages(request.getImages());

        // 5. reviews 테이블 저장
        Review review = Review.builder()
                .user(user)
                .hospital(hospital)
                .rating(request.getRating())
                .content(request.getContent())
                .receiptImageUrl(receiptImageUrl)
                .receiptVerified(true)
                .build();
        reviewRepository.save(review);

        // 6. review_images 테이블 저장 (sort_order 보존)
        for (int i = 0; i < imageUrls.size(); i++) {
            ReviewImage image = ReviewImage.builder()
                    .review(review)
                    .imageUrl(imageUrls.get(i))
                    .sortOrder(i)
                    .build();
            reviewImageRepository.save(image);
        }

        // 7. OCR 인증 1회성 소비 — 토큰 삭제
        ocrVerificationService.consumeOcrToken(userId, request.getYkiho());

        log.debug("리뷰 등록 완료: reviewId={}, userId={}, ykiho={}",
                review.getReviewId(), userId, request.getYkiho());
        return review.getReviewId();
    }

    // ── 병원별 리뷰 조회 (RV-007, HOS-011) ──────────────────────────

    /**
     * ykiho 기준 병원의 리뷰 목록을 페이징 조회한다.
     * 평균 별점·총 건수는 전체 기준 (페이지 무관).
     */
    @Transactional(readOnly = true)
    public HospitalReviewResponse getByHospital(String ykiho, int page, int size) {

        Hospital hospital = hospitalRepository.findByYkiho(ykiho)
                .orElseThrow(() -> new AuthException(
                        "HOSPITAL_NOT_FOUND",
                        "병원 정보를 찾을 수 없습니다.",
                        HttpStatus.NOT_FOUND));

        Long hospitalId = hospital.getHospitalId();
        PageRequest pageable = PageRequest.of(page, size);
        Page<Review> reviewPage = reviewRepository
                .findByHospital_HospitalIdOrderByCreatedAtDesc(hospitalId, pageable);

        // 평균 별점 (전체 리뷰 기준, 소수점 1자리)
        Double avgRaw = reviewRepository.findAvgRatingByHospitalId(hospitalId);
        double averageRating = avgRaw == null ? 0.0
                : BigDecimal.valueOf(avgRaw).setScale(1, RoundingMode.HALF_UP).doubleValue();

        long totalCount = reviewPage.getTotalElements();

        List<ReviewItemResponse> reviews = reviewPage.getContent().stream()
                .map(r -> ReviewItemResponse.of(r,
                        reviewImageRepository.findByReview_ReviewIdOrderBySortOrderAsc(r.getReviewId())))
                .toList();

        return HospitalReviewResponse.builder()
                .averageRating(averageRating)
                .totalCount(totalCount)
                .reviews(reviews)
                .build();
    }

    // ── 내 리뷰 조회 (RV-008, MENU-007) ─────────────────────────────

    /**
     * 로그인 사용자의 리뷰 목록을 페이징 조회한다.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getMyReviews(Long userId, int page, int size) {

        PageRequest pageable = PageRequest.of(page, size);
        Page<Review> reviewPage = reviewRepository
                .findByUser_UserIdOrderByCreatedAtDesc(userId, pageable);

        List<MyReviewResponse> reviews = reviewPage.getContent().stream()
                .map(r -> MyReviewResponse.of(r,
                        reviewImageRepository.findByReview_ReviewIdOrderBySortOrderAsc(r.getReviewId())))
                .toList();

        return Map.of(
                "totalCount", reviewPage.getTotalElements(),
                "reviews", reviews
        );
    }

    // ── 리뷰 삭제 (MENU-007) ─────────────────────────────────────────

    /**
     * 본인 리뷰를 삭제한다.
     * 삭제 순서: S3 파일 → review_images 행 → reviews 행
     */
    @Transactional
    public void delete(Long userId, Long reviewId) {

        // 1. 리뷰 존재 확인
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new AuthException(
                        "REVIEW_NOT_FOUND",
                        "리뷰를 찾을 수 없습니다.",
                        HttpStatus.NOT_FOUND));

        // 2. 본인 검증
        if (!review.getUser().getUserId().equals(userId)) {
            throw new AuthException(
                    "FORBIDDEN",
                    "본인의 리뷰만 삭제할 수 있습니다.",
                    HttpStatus.FORBIDDEN);
        }

        // 3. S3 파일 삭제 → review_images 행 삭제
        List<ReviewImage> images =
                reviewImageRepository.findByReview_ReviewIdOrderBySortOrderAsc(reviewId);
        for (ReviewImage image : images) {
            s3UploadService.delete(image.getImageUrl());
        }
        reviewImageRepository.deleteAll(images);

        // 4. reviews 행 삭제 (hard delete)
        reviewRepository.delete(review);
        log.debug("리뷰 삭제 완료: reviewId={}, userId={}", reviewId, userId);
    }

    // ── 내부 유틸 ────────────────────────────────────────────────────

    private void validateCreateRequest(ReviewCreateRequest request) {
        if (request.getRating() < 1 || request.getRating() > 5) {
            throw new AuthException(
                    "INVALID_RATING",
                    "별점은 1~5 사이의 값이어야 합니다",
                    HttpStatus.BAD_REQUEST);
        }
        if (request.getContent() != null && request.getContent().length() > MAX_CONTENT_LENGTH) {
            throw new AuthException(
                    "CONTENT_TOO_LONG",
                    "리뷰는 최대 2000자까지 입력 가능합니다",
                    HttpStatus.BAD_REQUEST);
        }
        List<MultipartFile> images = request.getImages();
        if (images != null && images.size() > MAX_IMAGES) {
            throw new AuthException(
                    "TOO_MANY_IMAGES",
                    "이미지는 최대 5장까지 첨부 가능합니다",
                    HttpStatus.BAD_REQUEST);
        }
    }

    private List<String> uploadImages(List<MultipartFile> images) throws IOException {
        List<String> urls = new ArrayList<>();
        if (images == null || images.isEmpty()) return urls;

        for (MultipartFile file : images) {
            if (file == null || file.isEmpty()) continue;
            String url = s3UploadService.upload(
                    file.getBytes(),
                    "reviews",
                    Optional.ofNullable(file.getContentType()).orElse("image/jpeg")
            );
            urls.add(url);
        }
        return urls;
    }
}
