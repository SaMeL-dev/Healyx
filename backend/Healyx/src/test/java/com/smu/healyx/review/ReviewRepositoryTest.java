package com.smu.healyx.review;

import com.smu.healyx.hospital.domain.Hospital;
import com.smu.healyx.hospital.repository.HospitalRepository;
import com.smu.healyx.review.domain.Review;
import com.smu.healyx.review.repository.ReviewRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("local")
public class ReviewRepositoryTest {

    @Autowired private ReviewRepository reviewRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private HospitalRepository hospitalRepository;

    @Test
    void 리뷰_저장_및_조회() {
        User user = userRepository.save(User.builder()
                .username("reviewer1")
                .passwordHash("hash")
                .realName("리뷰어")
                .email("reviewer@healyx.com")
                .nickname("리뷰어닉")
                .preferredLanguage("en")
                .build());

        Hospital hospital = hospitalRepository.save(Hospital.builder()
                .name("리뷰테스트병원")
                .type("의원")
                .address("서울시 테헤란로 1")
                .latitude(new BigDecimal("37.5"))
                .longitude(new BigDecimal("127.0"))
                .createdAt(LocalDateTime.now())
                .build());

        reviewRepository.save(Review.builder()
                .user(user)
                .hospital(hospital)
                .rating(5)
                .content("좋아요")
                .build());

        List<Review> result = reviewRepository.findByUser_UserId(user.getUserId());
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getRating()).isEqualTo(5);
    }

    @Test
    void 동일병원_중복리뷰_확인() {
        User user = userRepository.save(User.builder()
                .username("reviewer2")
                .passwordHash("hash")
                .realName("리뷰어2")
                .email("reviewer2@healyx.com")
                .nickname("리뷰어닉2")
                .preferredLanguage("en")
                .build());

        Hospital hospital = hospitalRepository.save(Hospital.builder()
                .name("중복테스트병원")
                .type("병원")
                .address("서울시 강남구 1")
                .latitude(new BigDecimal("37.5"))
                .longitude(new BigDecimal("127.0"))
                .createdAt(LocalDateTime.now())
                .build());

        reviewRepository.save(Review.builder()
                .user(user)
                .hospital(hospital)
                .rating(4)
                .build());

        assertThat(reviewRepository.existsByUser_UserIdAndHospital_HospitalId(
                user.getUserId(), hospital.getHospitalId())).isTrue();
    }
}