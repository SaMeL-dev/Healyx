package com.smu.healyx.hospital.domain;

import com.smu.healyx.hira.dto.HospitalDto;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "hospitals")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class Hospital {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "hospital_id")
    private Long hospitalId;

    @Column(name = "ykiho", unique = true, length = 200)
    private String ykiho;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "type", nullable = false, length = 20)
    private String type;

    @Column(name = "address", nullable = false, length = 255)
    private String address;

    @Column(name = "latitude", nullable = false, precision = 10, scale = 7)
    private BigDecimal latitude;

    @Column(name = "longitude", nullable = false, precision = 10, scale = 7)
    private BigDecimal longitude;

    @Column(name = "phone", length = 20)
    private String phone;

    @Column(name = "business_number", length = 20)
    private String businessNumber;

    @Column(name = "is_foreign_certified", nullable = false,
            columnDefinition = "TINYINT(1) DEFAULT 0")
    private boolean isForeignCertified;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
    }

    // ── HIRA DTO 기반 팩토리 ───────────────────────────────────────────

    /**
     * HIRA API 응답(HospitalDto)으로 신규 Hospital 엔티티를 생성한다.
     * address/type이 null인 경우 빈 문자열로 방어 처리.
     */
    public static Hospital fromHiraDto(HospitalDto dto) {
        return Hospital.builder()
                .ykiho(dto.getYkiho())
                .name(dto.getHospitalName())
                .type(dto.getHospitalType() != null ? dto.getHospitalType() : "")
                .address(dto.getAddress() != null ? dto.getAddress() : "")
                .latitude(BigDecimal.valueOf(dto.getLatitude()))
                .longitude(BigDecimal.valueOf(dto.getLongitude()))
                .phone(dto.getTelephone())
                .isForeignCertified(dto.isForeignCertified())
                .build();
    }

    /**
     * HIRA API 최신 응답으로 기존 Hospital 행을 갱신한다.
     * hospitalId·ykiho·createdAt은 변경하지 않음.
     */
    public void updateFromHira(HospitalDto dto) {
        this.name             = dto.getHospitalName();
        this.type             = dto.getHospitalType() != null ? dto.getHospitalType() : this.type;
        this.address          = dto.getAddress() != null ? dto.getAddress() : this.address;
        this.latitude         = BigDecimal.valueOf(dto.getLatitude());
        this.longitude        = BigDecimal.valueOf(dto.getLongitude());
        this.phone            = dto.getTelephone();
        this.isForeignCertified = dto.isForeignCertified();
    }
}