package com.smu.healyx.cost.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "hospital_type_adjustment")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class HospitalTypeAdjustment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "type_adj_id")
    private Long typeAdjId;

    @Column(name = "hospital_type", nullable = false, length = 20)
    private String hospitalType;

    @Column(name = "adj_factor", nullable = false)
    private double adjFactor;
}
