package com.smu.healyx.hospital.seed;

import com.smu.healyx.hospital.repository.ForeignCertifiedHospitalRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;

@Component
@RequiredArgsConstructor
@Slf4j
public class ForeignCertifiedHospitalSeeder implements CommandLineRunner {

    private final ForeignCertifiedHospitalRepository repository;
    private final JdbcTemplate jdbcTemplate;

    @Override
    @Transactional
    public void run(String... args) {
        long count = repository.count();
        if (count > 0) {
            log.info("foreign_certified_hospitals 시드 SKIP (기존 {}건 존재)", count);
            return;
        }

        try {
            ClassPathResource resource = new ClassPathResource("seed/foreign_certified_hospitals_data.sql");
            String sql = new String(resource.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
            jdbcTemplate.execute(sql);

            long inserted = repository.count();
            log.info("foreign_certified_hospitals 시드 INSERT 완료: {}건", inserted);
        } catch (Exception e) {
            log.error("foreign_certified_hospitals 시드 실패: {}", e.getMessage());
        }
    }
}
