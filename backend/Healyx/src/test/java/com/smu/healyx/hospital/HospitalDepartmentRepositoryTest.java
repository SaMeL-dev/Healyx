package com.smu.healyx.hospital;

import com.smu.healyx.hospital.domain.Hospital;
import com.smu.healyx.hospital.domain.HospitalDepartment;
import com.smu.healyx.hospital.repository.HospitalDepartmentRepository;
import com.smu.healyx.hospital.repository.HospitalRepository;
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
public class HospitalDepartmentRepositoryTest {

    @Autowired
    private HospitalDepartmentRepository hospitalDepartmentRepository;

    @Autowired
    private HospitalRepository hospitalRepository;

    @Test
    void 진료과_저장_및_조회() {
        Hospital hospital = hospitalRepository.save(Hospital.builder()
                .name("테스트병원")
                .type("의원")
                .address("서울시 강남구 테헤란로 123")
                .latitude(new BigDecimal("37.5"))
                .longitude(new BigDecimal("127.0"))
                .createdAt(LocalDateTime.now())
                .build());

        HospitalDepartment dept = HospitalDepartment.builder()
                .hospital(hospital)
                .departmentName("정형외과")
                .build();

        hospitalDepartmentRepository.save(dept);

        List<HospitalDepartment> result = hospitalDepartmentRepository
                .findByHospital_HospitalId(hospital.getHospitalId());

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getDepartmentName()).isEqualTo("정형외과");
    }
}