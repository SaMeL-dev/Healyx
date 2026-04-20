package com.smu.healyx;

import com.smu.healyx.hospital.domain.Hospital;
import com.smu.healyx.hospital.repository.HospitalRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("local")
public class HospitalRepositoryTest {

    @Autowired
    private HospitalRepository hospitalRepository;

    @Test
    void 병원_저장_및_조회() {
        Hospital hospital = Hospital.builder()
                .name("테스트병원")
                .type("의원")
                .address("탕정면로 123번길 17-4")
                .latitude(new BigDecimal("36.4"))
                .longitude(new BigDecimal("127.2"))
                .createdAt(LocalDateTime.now())
                .build();

        hospitalRepository.save(hospital);

        Optional<Hospital> found = hospitalRepository.findByYkiho(null);
        assertThat(hospitalRepository.findAll()).hasSize(1);
        assertThat(hospitalRepository.findAll().get(0).getName()).isEqualTo("테스트병원");
    }

    @Test
    void ykiho_중복_확인() {
        Hospital hospital = Hospital.builder()
                .ykiho("TEST12345")
                .name("테스트병원2")
                .type("병원")
                .address("서울시 강남구 테헤란로 123")
                .latitude(new BigDecimal("37.5"))
                .longitude(new BigDecimal("127.0"))
                .createdAt(LocalDateTime.now())
                .build();

        hospitalRepository.save(hospital);

        assertThat(hospitalRepository.existsByYkiho("TEST12345")).isTrue();
        assertThat(hospitalRepository.existsByYkiho("NONE99999")).isFalse();
    }
}