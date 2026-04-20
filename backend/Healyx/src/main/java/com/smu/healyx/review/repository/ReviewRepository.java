package com.smu.healyx.review.repository;

import com.smu.healyx.review.domain.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ReviewRepository extends JpaRepository<Review, Long> {
    List<Review> findByUser_UserId(Long userId);
    List<Review> findByHospital_HospitalId(Long hospitalId);
    boolean existsByUser_UserIdAndHospital_HospitalId(Long userId, Long hospitalId);
}