package com.smu.healyx.review.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.exception.ExternalApiException;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.review.dto.*;
import com.smu.healyx.review.service.OcrVerificationService;
import com.smu.healyx.review.service.ReviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@Slf4j
@Tag(name = "Review", description = "리뷰 API")
@RestController
@RequestMapping("/api/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final OcrVerificationService ocrVerificationService;
    private final ReviewService reviewService;

    // ── 0. 리뷰 전용 병원 검색 (HX_R_002, UI-REV-01 / UI-REV-02) — 게스트 허용 ─

    @Operation(
            summary = "리뷰 전용 병원 검색",
            description = "병원명·지역으로 HIRA에서 직접 검색. 평균 별점·리뷰 수 포함. " +
                    "리뷰 작성 진입 화면(UI-REV-01,02)에서 사용. SecurityConfig상 GET /api/reviews/hospitals/** permitAll."
    )
    @GetMapping("/hospitals/search")
    public ResponseEntity<ApiResponse<ReviewHospitalSearchResponse>> searchHospitals(
            @RequestParam String name,
            @RequestParam(required = false) String region,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        ReviewHospitalSearchResponse response =
                reviewService.searchHospitalForReview(name, region, page, size);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    // ── 1. 영수증 OCR 인증 (RV-002~004) ─────────────────────────────

    @Operation(
            summary = "영수증 OCR 인증",
            description = "영수증 이미지를 OCR 처리하여 선택한 병원과 일치하는지 확인. 인증 성공 시 Redis에 10분간 상태 저장."
    )
    @PostMapping(value = "/ocr", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<OcrVerifyResponse>> verifyReceipt(
            @RequestPart("receiptImage") MultipartFile receiptImage,
            @RequestPart("ykiho") String ykiho,
            Authentication authentication) {

        Long userId = SecurityUtils.extractUserId(authentication);

        try {
            OcrVerifyRequest request = new OcrVerifyRequest();
            request.setReceiptImage(receiptImage);
            request.setYkiho(ykiho);

            OcrVerifyResponse response = ocrVerificationService.verify(userId, request);
            return ResponseEntity.ok(ApiResponse.success(response));

        } catch (ExternalApiException e) {
            // Vision OCR 인식 불가 → 422
            if ("VISION_NO_TEXT".equals(e.getErrorCode()) || "VISION_PARSE_ERROR".equals(e.getErrorCode())) {
                return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                        .body(ApiResponse.error("OCR_UNREADABLE", "재촬영이 필요합니다"));
            }
            throw e;
        } catch (Exception e) {
            log.error("OCR 인증 오류: userId={}, ykiho={}, error={}", userId, ykiho, e.getMessage());
            throw new RuntimeException(e);
        }
    }

    // ── 2. 리뷰 등록 (RV-005~007) ────────────────────────────────────

    @Operation(
            summary = "리뷰 등록",
            description = "OCR 인증 완료 후 리뷰를 등록한다. 이미지 최대 5장, 본문 최대 2000자."
    )
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<Map<String, Long>>> createReview(
            @RequestPart("ykiho") String ykiho,
            @RequestPart("rating") String ratingStr,
            @RequestPart(value = "content", required = false) String content,
            @RequestPart(value = "images", required = false) List<MultipartFile> images,
            Authentication authentication) {

        Long userId = SecurityUtils.extractUserId(authentication);

        try {
            ReviewCreateRequest request = new ReviewCreateRequest();
            request.setYkiho(ykiho);
            request.setRating(Integer.parseInt(ratingStr));
            request.setContent(content);
            request.setImages(images);

            Long reviewId = reviewService.create(userId, request);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success(Map.of("reviewId", reviewId)));

        } catch (Exception e) {
            log.error("리뷰 등록 오류: userId={}, ykiho={}, error={}", userId, ykiho, e.getMessage());
            throw new RuntimeException(e);
        }
    }

    // ── 3. 병원별 리뷰 조회 (RV-007, HOS-011) — 인증 불필요 ──────────

    @Operation(
            summary = "병원별 리뷰 조회",
            description = "ykiho로 특정 병원의 리뷰 목록을 페이징 조회한다. 비로그인 허용."
    )
    @GetMapping("/hospitals/{ykiho}")
    public ResponseEntity<ApiResponse<HospitalReviewResponse>> getHospitalReviews(
            @PathVariable String ykiho,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        HospitalReviewResponse response = reviewService.getByHospital(ykiho, page, size);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    // ── 4. 내 리뷰 조회 (RV-008, MENU-007) ──────────────────────────

    @Operation(
            summary = "내 리뷰 조회",
            description = "로그인 사용자의 리뷰 목록을 최신순 페이징 조회한다."
    )
    @GetMapping("/my")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getMyReviews(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication authentication) {

        Long userId = SecurityUtils.extractUserId(authentication);
        Map<String, Object> response = reviewService.getMyReviews(userId, page, size);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    // ── 5. 리뷰 삭제 (MENU-007) ──────────────────────────────────────

    @Operation(
            summary = "리뷰 삭제",
            description = "본인 리뷰를 삭제한다. S3 이미지 → review_images → reviews 순서로 삭제."
    )
    @DeleteMapping("/{reviewId}")
    public ResponseEntity<ApiResponse<Void>> deleteReview(
            @PathVariable Long reviewId,
            Authentication authentication) {

        Long userId = SecurityUtils.extractUserId(authentication);
        reviewService.delete(userId, reviewId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
