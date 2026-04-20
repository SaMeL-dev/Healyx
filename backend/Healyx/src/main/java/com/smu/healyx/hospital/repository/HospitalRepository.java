package com.smu.healyx.hospital.repository;

import com.smu.healyx.hospital.domain.Hospital;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface HospitalRepository extends JpaRepository<Hospital, Long> {
    Optional<Hospital> findByYkiho(String ykiho);
    boolean existsByYkiho(String ykiho);
}