package com.smu.healyx.review.repository;

import com.smu.healyx.review.domain.Review;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface ReviewRepository extends JpaRepository<Review, Long> {

    // ── 기존 ──────────────────────────────────────
    List<Review> findByUser_UserId(Long userId);
    List<Review> findByHospital_HospitalId(Long hospitalId);
    boolean existsByUser_UserIdAndHospital_HospitalId(Long userId, Long hospitalId);

    // 내 리뷰 목록 — hospital JOIN FETCH(N+1 방지), 최신순 (MyReviewService에서 사용)
    @Query("SELECT r FROM Review r JOIN FETCH r.hospital WHERE r.user.userId = :userId ORDER BY r.createdAt DESC")
    List<Review> findMyReviewsWithHospital(@Param("userId") Long userId);

    // ── 신규: 본인 리뷰 단건 조회 (UI-REV-03-P 정합) ──
    /**
     * 사용자 + 병원 조합으로 작성된 리뷰 단건을 조회한다.
     * uq_review_user_hospital UNIQUE 제약상 결과는 0건 또는 1건.
     *
     * <p>병원 상세 응답의 myReviewExists/myReviewId 필드 채움 용도.
     * existsBy~만으론 reviewId까지 알 수 없어 별도 메소드 추가.
     */
    Optional<Review> findByUser_UserIdAndHospital_HospitalId(Long userId, Long hospitalId);

    // ── 신규: 병원 추천 스코어링용 집계 ──────────────
    @Query("SELECT AVG(r.rating) FROM Review r WHERE r.hospital.hospitalId = :hospitalId")
    Double findAvgRatingByHospitalId(@Param("hospitalId") Long hospitalId);

    @Query("SELECT COUNT(r) FROM Review r WHERE r.hospital.hospitalId = :hospitalId")
    int countByHospitalId(@Param("hospitalId") Long hospitalId);

    /**
     * 여러 병원의 리뷰 평균 별점·건수를 한 번에 집계한다.
     * 반환: [hospitalId(Long), avgRating(Double), reviewCount(Long)] per row.
     * 리뷰 없는 병원은 결과에 포함되지 않음 → 조회 안 된 병원은 avgRating=null, reviewCount=0 처리.
     */
    @Query("SELECT r.hospital.hospitalId, AVG(r.rating), COUNT(r) " +
           "FROM Review r WHERE r.hospital.hospitalId IN :hospitalIds " +
           "GROUP BY r.hospital.hospitalId")
    List<Object[]> findRatingStatsByHospitalIds(
            @Param("hospitalIds") Collection<Long> hospitalIds);

    // ── 신규: 페이징 조회 ───────────────────────────
    Page<Review> findByHospital_HospitalIdOrderByCreatedAtDesc(Long hospitalId, Pageable pageable);
    Page<Review> findByUser_UserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    // ── 전체 최신 리뷰 N건 조회 (메인화면 미리보기) — hospital·user JOIN FETCH(N+1 방지) ──
    @Query("SELECT r FROM Review r JOIN FETCH r.hospital JOIN FETCH r.user ORDER BY r.createdAt DESC")
    List<Review> findLatestReviewsWithHospital(Pageable pageable);
}
