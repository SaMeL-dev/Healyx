package com.smu.healyx.hospital.repository;

import com.smu.healyx.hospital.domain.ForeignCertifiedHospital;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.Collection;
import java.util.List;

public interface ForeignCertifiedHospitalRepository extends JpaRepository<ForeignCertifiedHospital, Long> {
    Optional<ForeignCertifiedHospital> findByYkiho(String ykiho);
    boolean existsByYkiho(String ykiho);

    // ✅ 추가: 병원 목록 일괄 조회 (N+1 방지)
    List<ForeignCertifiedHospital> findAllByYkihoIn(Collection<String> ykihos);
}