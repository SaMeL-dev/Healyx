package com.smu.healyx.cost.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "hospital_type_adjustment", indexes = {
        @Index(name = "idx_hosptypeadj_clcd", columnList = "cl_cd")
})
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class HospitalTypeAdjustment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "type_adj_id")
    private Long typeAdjId;

    @Column(name = "cl_cd", nullable = false, length = 20)
    private String clCd;

    @Column(name = "adj_factor", nullable = false)
    private double adjFactor;
}
