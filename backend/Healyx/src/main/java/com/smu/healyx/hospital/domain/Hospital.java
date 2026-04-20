package com.smu.healyx.hospital.domain;

import jakarta.persistence.*;
import lombok.*;
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
    private java.math.BigDecimal latitude;

    @Column(name = "longitude", nullable = false, precision = 10, scale = 7)
    private java.math.BigDecimal longitude;

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
}