package com.smu.healyx.hospital.repository;

import com.smu.healyx.hospital.domain.Hospital;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface HospitalRepository extends JpaRepository<Hospital, Long> {

    // ── 기존 ──────────────────────────────────────
    Optional<Hospital> findByYkiho(String ykiho);
    boolean existsByYkiho(String ykiho);

    // ── 신규: Haversine 반경 내 진료과 보유 병원 조회 ──
    /**
     * 사용자 위치(lat, lng)에서 radiusKm 이내에 있는 병원 중
     * 특정 진료과(department)를 보유한 병원 목록 반환.
     * DISTINCT: hospital_departments JOIN으로 인한 중복 제거.
     * LEAST(1.0, ...): acos 도메인 오류 방지용 클램핑.
     */
    @Query(value = """
            SELECT DISTINCT h.*
            FROM hospitals h
            JOIN hospital_departments hd ON h.hospital_id = hd.hospital_id
            WHERE hd.department_name = :department
              AND (6371 * acos(
                      LEAST(1.0,
                            cos(radians(:lat)) * cos(radians(h.latitude))
                            * cos(radians(h.longitude) - radians(:lng))
                            + sin(radians(:lat)) * sin(radians(h.latitude))
                      )
                  )) <= :radiusKm
            """, nativeQuery = true)
    List<Hospital> findHospitalsWithinRadius(
            @Param("lat")      double lat,
            @Param("lng")      double lng,
            @Param("radiusKm") double radiusKm,
            @Param("department") String department
    );
}