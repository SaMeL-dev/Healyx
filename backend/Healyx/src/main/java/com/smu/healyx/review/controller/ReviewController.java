package com.smu.healyx.review.controller;

import com.smu.healyx.common.dto.ApiResponse;
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

import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * 리뷰 관련 컨트롤러.
 *
 * <p>내 리뷰 목록 조회·삭제는 {@link MyReviewController}로 분리되어 있으며
 * 본 컨트롤러는 다음 4개 엔드포인트만 책임진다:
 * <ul>
 *   <li>GET    /api/reviews/hospitals/search        — 리뷰용 병원 검색 (게스트 허용)</li>
 *   <li>POST   /api/reviews/ocr                     — 영수증 OCR 인증</li>
 *   <li>POST   /api/reviews                         — 리뷰 등록</li>
 *   <li>GET    /api/reviews/hospitals/{ykiho}       — 병원 상세 + 리뷰 조회 (게스트 허용)</li>
 * </ul>
 */
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

    // ── 1. 영수증 OCR 인증 (HX_R_004, RV-002~004) ────────────────────

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

            // 외부 명세 메소드명으로 호출 (프로그램 목록 v1.0 정합)
            OcrVerifyResponse response = ocrVerificationService.verifyVisitByReceipt(userId, request);
            return ResponseEntity.ok(ApiResponse.success(response));

        } catch (ExternalApiException e) {
            // Vision OCR 인식 불가 → 422
            if ("VISION_NO_TEXT".equals(e.getErrorCode()) || "VISION_PARSE_ERROR".equals(e.getErrorCode())) {
                return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                        .body(ApiResponse.error("OCR_UNREADABLE", "재촬영이 필요합니다"));
            }
            throw e;
        } catch (IOException e) {                       // ← Exception 대신 IOException만 감쌈
            log.error("OCR 인증 IO 오류: userId={}, ykiho={}, error={}", userId, ykiho, e.getMessage());
            throw new RuntimeException(e);
        }
        // AuthException은 catch하지 않고 GlobalExceptionHandler로 위임 → 400 RECEIPT_MISMATCH 정상 응답
    }

    // ── 2. 리뷰 등록 (HX_R_007, RV-005~007) ──────────────────────────

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

            // 외부 명세 메소드명으로 호출 (프로그램 목록 v1.0 정합)
            Long reviewId = reviewService.createReview(userId, request);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success(Map.of("reviewId", reviewId)));

        } catch (IOException e) {
            log.error("리뷰 등록 오류: userId={}, ykiho={}, error={}", userId, ykiho, e.getMessage());
            throw new RuntimeException(e);
        }
        // AuthException은 catch하지 않고 GlobalExceptionHandler로 위임
        // → OCR_TOKEN_EXPIRED: 400, REVIEW_ALREADY_EXISTS: 409, HOSPITAL_NOT_FOUND: 404 등 정상 응답
    }

    // ── 3. 병원 상세 + 리뷰 조회 (HX_R_008, UI-HOS-08R / UI-REV-03) — 게스트 허용 ──

    @Operation(
            summary = "병원 상세 + 리뷰 조회",
            description = "ykiho로 병원 메타 정보(이름·타입·주소·전화·외국인 인증) + 리뷰 목록을 페이징 조회한다. " +
                    "UI-HOS-08R(병원 찾기 진입) 및 UI-REV-03(리뷰 검색 진입) 양쪽에서 사용. " +
                    "로그인 사용자는 myReviewExists/myReviewId가 채워져 UI-REV-03-P 중복 작성 차단을 클릭 시점에 처리할 수 있다. " +
                    "게스트 호출도 200 정상 응답."
    )
    @GetMapping("/hospitals/{ykiho}")
    public ResponseEntity<ApiResponse<HospitalReviewResponse>> getHospitalReviews(
            @PathVariable String ykiho,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication authentication) {

        // 게스트 허용 — 비로그인 시 userId = null
        Long userId = SecurityUtils.extractUserIdNullable(authentication);

        // 외부 명세 메소드명으로 호출 (프로그램 목록 v1.0 정합)
        HospitalReviewResponse response =
                reviewService.getReviewsByHospital(ykiho, userId, page, size);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    // ── 4. 메인화면 최신 리뷰 조회 (게스트 허용) ─────────────────────────

    @Operation(
            summary = "메인화면 최신 리뷰 조회",
            description = "전체 리뷰 중 최신 N건을 반환한다. 병원명·마스킹 닉네임·내용·별점 포함. 게스트 허용."
    )
    @GetMapping("/latest")
    public ResponseEntity<ApiResponse<List<LatestReviewItem>>> getLatestReviews(
            @RequestParam(defaultValue = "2") int size) {

        List<LatestReviewItem> items = reviewService.getLatestReviews(size);
        return ResponseEntity.ok(ApiResponse.success(items));
    }

    // ── 내 리뷰 조회 / 삭제는 MyReviewController로 일원화 (main 머지 후) ──
}
