package com.smu.healyx.hospital.repository;

import com.smu.healyx.hospital.domain.ForeignCertifiedHospital;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ForeignCertifiedHospitalRepository extends JpaRepository<ForeignCertifiedHospital, Long> {
    Optional<ForeignCertifiedHospital> findByYkiho(String ykiho);
    boolean existsByYkiho(String ykiho);
}