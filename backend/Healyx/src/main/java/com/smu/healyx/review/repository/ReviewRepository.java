package com.smu.healyx.review.repository;

import com.smu.healyx.review.domain.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ReviewRepository extends JpaRepository<Review, Long> {

    // ── 기존 ──────────────────────────────────────
    List<Review> findByUser_UserId(Long userId);
    List<Review> findByHospital_HospitalId(Long hospitalId);
    boolean existsByUser_UserIdAndHospital_HospitalId(Long userId, Long hospitalId);

    // 내 리뷰 목록 — hospital JOIN FETCH(N+1 방지), 최신순
    @Query("SELECT r FROM Review r JOIN FETCH r.hospital WHERE r.user.userId = :userId ORDER BY r.createdAt DESC")
    List<Review> findMyReviewsWithHospital(@Param("userId") Long userId);

    // ── 신규: 병원 추천 스코어링용 집계 ──────────────
    @Query("SELECT AVG(r.rating) FROM Review r WHERE r.hospital.hospitalId = :hospitalId")
    Double findAvgRatingByHospitalId(@Param("hospitalId") Long hospitalId);

    @Query("SELECT COUNT(r) FROM Review r WHERE r.hospital.hospitalId = :hospitalId")
    int countByHospitalId(@Param("hospitalId") Long hospitalId);
}