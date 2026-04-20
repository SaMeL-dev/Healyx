package com.smu.healyx.cost.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "cost_adjustment")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class CostAdjustment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "cost_adj_id")
    private Long costAdjId;

    @Column(name = "age_max", nullable = false)
    private int ageMax;

    @Column(name = "gender", nullable = false, length = 1)
    private String gender;

    @Column(name = "adj_factor", nullable = false)
    private double adjFactor;

    @Column(name = "adj_factor_full", nullable = false)
    private double adjFactorFull;
}
