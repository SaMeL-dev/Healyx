package com.smu.healyx.hospital.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "foreign_certified_hospitals")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class ForeignCertifiedHospital {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "cert_id")
    private Long certId;

    @Column(name = "ykiho", nullable = false, unique = true, length = 200)
    private String ykiho;

    @Column(name = "name", nullable = false, length = 100)
    private String name;
}