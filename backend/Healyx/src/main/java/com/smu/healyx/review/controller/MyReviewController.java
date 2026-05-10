package com.smu.healyx.review.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.common.security.SecurityUtils;
import com.smu.healyx.review.dto.MyReviewResponse;
import com.smu.healyx.review.service.MyReviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "My Review", description = "내 리뷰 보관함 API")
@RestController
@RequestMapping("/api/reviews/my")
@RequiredArgsConstructor
public class MyReviewController {

    private final MyReviewService myReviewService;

    /** 내 리뷰 목록 조회 — JWT 필요 */
    @Operation(summary = "내 리뷰 목록 조회", description = "본인이 작성한 리뷰를 최신순으로 반환합니다.")
    @GetMapping
    public ResponseEntity<ApiResponse<List<MyReviewResponse>>> getMyReviews(
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        return ResponseEntity.ok(ApiResponse.success(myReviewService.getMyReviews(userId)));
    }

    /** 내 리뷰 삭제 — JWT 필요 */
    @Operation(summary = "내 리뷰 삭제", description = "본인이 작성한 리뷰를 삭제합니다.")
    @DeleteMapping("/{reviewId}")
    public ResponseEntity<ApiResponse<Void>> deleteMyReview(
            @PathVariable Long reviewId,
            Authentication authentication) {
        Long userId = SecurityUtils.extractUserId(authentication);
        myReviewService.deleteMyReview(userId, reviewId);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
