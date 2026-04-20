package com.smu.healyx.community;

import com.smu.healyx.community.domain.Report;
import com.smu.healyx.community.repository.ReportRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("local")
public class ReportRepositoryTest {

    @Autowired private ReportRepository reportRepository;
    @Autowired private UserRepository userRepository;

    @Test
    void 신고_저장_및_조회() {
        User reporter = userRepository.save(User.builder()
                .username("reportuser1").passwordHash("hash")
                .realName("신고유저").email("report@healyx.com")
                .nickname("신고닉").preferredLanguage("en")
                .build());

        reportRepository.save(Report.builder()
                .reporter(reporter)
                .targetType("POST")
                .targetId(1L)
                .reason("부적절한 내용")
                .build());

        List<Report> result = reportRepository
                .findByTargetTypeAndTargetId("POST", 1L);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getStatus()).isEqualTo("PENDING");
    }

    @Test
    void 상태별_신고_조회() {
        User reporter = userRepository.save(User.builder()
                .username("reportuser2").passwordHash("hash")
                .realName("신고유저2").email("report2@healyx.com")
                .nickname("신고닉2").preferredLanguage("en")
                .build());

        reportRepository.save(Report.builder()
                .reporter(reporter)
                .targetType("COMMENT")
                .targetId(2L)
                .reason("스팸")
                .build());

        List<Report> pending = reportRepository.findByStatus("PENDING");
        assertThat(pending).isNotEmpty();
    }
}
