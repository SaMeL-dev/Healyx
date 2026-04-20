package com.smu.healyx.review;

import com.smu.healyx.hospital.domain.Hospital;
import com.smu.healyx.hospital.repository.HospitalRepository;
import com.smu.healyx.review.domain.Review;
import com.smu.healyx.review.domain.ReviewImage;
import com.smu.healyx.review.repository.ReviewImageRepository;
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
public class ReviewImageRepositoryTest {

    @Autowired private ReviewImageRepository reviewImageRepository;
    @Autowired private ReviewRepository reviewRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private HospitalRepository hospitalRepository;

    @Test
    void 리뷰이미지_저장_및_순서조회() {
        User user = userRepository.save(User.builder()
                .username("imguser1")
                .passwordHash("hash")
                .realName("이미지유저")
                .email("imguser@healyx.com")
                .nickname("이미지닉")
                .preferredLanguage("en")
                .build());

        Hospital hospital = hospitalRepository.save(Hospital.builder()
                .name("이미지테스트병원")
                .type("의원")
                .address("서울시 강남구 1")
                .latitude(new BigDecimal("37.5"))
                .longitude(new BigDecimal("127.0"))
                .createdAt(LocalDateTime.now())
                .build());

        Review review = reviewRepository.save(Review.builder()
                .user(user)
                .hospital(hospital)
                .rating(5)
                .build());

        reviewImageRepository.save(ReviewImage.builder()
                .review(review)
                .imageUrl("https://s3.amazonaws.com/test1.jpg")
                .sortOrder(1)
                .build());

        reviewImageRepository.save(ReviewImage.builder()
                .review(review)
                .imageUrl("https://s3.amazonaws.com/test2.jpg")
                .sortOrder(0)
                .build());

        List<ReviewImage> result = reviewImageRepository
                .findByReview_ReviewIdOrderBySortOrderAsc(review.getReviewId());

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getSortOrder()).isEqualTo(0);
        assertThat(result.get(1).getSortOrder()).isEqualTo(1);
    }
}