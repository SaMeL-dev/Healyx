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
import java.util.Optional;

/**
 * 리뷰 작성·검색·병원별 조회 서비스.
 *
 * <p>내 리뷰 목록 조회·삭제 책임은 {@link MyReviewService}로 분리되어 있어
 * 본 서비스는 다음 책임만 담당한다:
 * <ul>
 *   <li>HX_R_002 — 리뷰 전용 병원 검색 (위임)</li>
 *   <li>HX_R_007 — 리뷰 등록</li>
 *   <li>HX_R_008 — 병원 상세 + 리뷰 목록 조회</li>
 * </ul>
 */
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
    private final ReviewHospitalSearchService reviewHospitalSearchService;

    private static final int MAX_IMAGES = 5;
    private static final int MAX_CONTENT_LENGTH = 2000;

    // ════════════════════════════════════════════════════════════════
    // 외부 명세 메소드 (프로그램 목록 v1.0 기준)
    //
    // 컨트롤러는 외부 명세 메소드명을 통해 호출하고,
    // 내부 구현은 기존 메소드명(create/getByHospital)을 그대로 유지하여
    // 단위 테스트와 내부 호출자에 영향을 주지 않는다.
    // v4의 mapBodyIconToKeyword → BodyIconService.getKeywords 위임 패턴과 동일.
    // ════════════════════════════════════════════════════════════════

    /** HX_R_002: 리뷰 작성 진입 화면에서 병원을 직접 검색한다. */
    public ReviewHospitalSearchResponse searchHospitalForReview(
            String name, String region, int page, int size) {
        return reviewHospitalSearchService.search(name, region, page, size);
    }

    /** HX_R_007: 리뷰 유효성 검사 및 등록 */
    public Long createReview(Long userId, ReviewCreateRequest request) throws IOException {
        return create(userId, request);
    }

    /** HX_R_008: 병원 상세 리뷰 리스트 조회 */
    public HospitalReviewResponse getReviewsByHospital(
            String ykiho, Long userId, int page, int size) {
        return getByHospital(ykiho, userId, page, size);
    }

    // ════════════════════════════════════════════════════════════════
    // 내부 구현
    // ════════════════════════════════════════════════════════════════

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

    // ── 병원 상세 + 리뷰 조회 (RV-007, HOS-011) ──────────────────────

    /**
     * ykiho 기준 병원의 상세 정보 + 리뷰 목록을 페이징 조회한다.
     *
     * <p>UI-HOS-08R / UI-REV-03 정합:
     * 병원 메타 5필드(이름·타입·주소·전화·외국인 인증) + 리뷰 집계 + 리뷰 목록.
     *
     * <p>UI-REV-03-P 정합:
     * userId가 null이 아닐 경우 본인 리뷰 존재 여부와 reviewId를 함께 반환하여
     * 클라이언트가 "리뷰 쓰기" 클릭 시점에 중복 작성을 차단할 수 있게 한다.
     *
     * @param ykiho  병원 요양기호
     * @param userId 호출 사용자 ID. 게스트면 null
     * @param page   0-base 페이지
     * @param size   페이지 크기
     */
    @Transactional(readOnly = true)
    public HospitalReviewResponse getByHospital(String ykiho, Long userId, int page, int size) {

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

        // 본인 리뷰 식별 (로그인 사용자만 — 게스트는 false/null)
        boolean myReviewExists = false;
        Long myReviewId = null;
        if (userId != null) {
            Optional<Review> myReview = reviewRepository
                    .findByUser_UserIdAndHospital_HospitalId(userId, hospitalId);
            if (myReview.isPresent()) {
                myReviewExists = true;
                myReviewId = myReview.get().getReviewId();
            }
        }

        List<ReviewItemResponse> reviews = reviewPage.getContent().stream()
                .map(r -> {
                    List<String> presignedUrls = s3UploadService.presignAll(
                            reviewImageRepository.findByReview_ReviewIdOrderBySortOrderAsc(r.getReviewId())
                                    .stream().map(ReviewImage::getImageUrl).toList());
                    return ReviewItemResponse.of(r, presignedUrls);
                })
                .toList();

        return HospitalReviewResponse.builder()
                // 병원 메타 (UI-HOS-08R / UI-REV-03 정합)
                .hospitalName(hospital.getName())
                .hospitalType(hospital.getType())
                .address(hospital.getAddress())
                .telephone(hospital.getPhone())
                .foreignCertified(hospital.isForeignCertified())
                // 리뷰 집계
                .averageRating(averageRating)
                .totalCount(totalCount)
                // 본인 리뷰 여부 (UI-REV-03-P 정합)
                .myReviewExists(myReviewExists)
                .myReviewId(myReviewId)
                // 페이징 리뷰 목록
                .reviews(reviews)
                .build();
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
