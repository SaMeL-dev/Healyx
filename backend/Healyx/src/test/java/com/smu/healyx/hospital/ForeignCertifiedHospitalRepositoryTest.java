package com.smu.healyx.hospital;

import com.smu.healyx.hospital.domain.ForeignCertifiedHospital;
import com.smu.healyx.hospital.repository.ForeignCertifiedHospitalRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("local")
public class ForeignCertifiedHospitalRepositoryTest {

    @Autowired
    private ForeignCertifiedHospitalRepository foreignCertifiedHospitalRepository;

    @Test
    void 외국인유치인증병원_저장_및_조회() {
        ForeignCertifiedHospital hospital = ForeignCertifiedHospital.builder()
                .ykiho("TEST12345")
                .name("테스트인증병원")
                .build();

        foreignCertifiedHospitalRepository.save(hospital);

        Optional<ForeignCertifiedHospital> found = foreignCertifiedHospitalRepository.findByYkiho("TEST12345");
        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("테스트인증병원");
    }

    @Test
    void ykiho_존재여부_확인() {
        ForeignCertifiedHospital hospital = ForeignCertifiedHospital.builder()
                .ykiho("CERT99999")
                .name("테스트인증병원2")
                .build();

        foreignCertifiedHospitalRepository.save(hospital);

        assertThat(foreignCertifiedHospitalRepository.existsByYkiho("CERT99999")).isTrue();
        assertThat(foreignCertifiedHospitalRepository.existsByYkiho("NONE00000")).isFalse();
    }
}