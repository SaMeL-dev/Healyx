package com.smu.healyx.review.repository;

import com.smu.healyx.review.domain.ReviewImage;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ReviewImageRepository extends JpaRepository<ReviewImage, Long> {
    List<ReviewImage> findByReview_ReviewIdOrderBySortOrderAsc(Long reviewId);
}