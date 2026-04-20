package com.smu.healyx.cost.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "region_adjustment")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class RegionAdjustment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "region_adj_id")
    private Long regionAdjId;

    @Column(name = "region", nullable = false, length = 50)
    private String region;

    @Column(name = "adj_factor", nullable = false)
    private double adjFactor;
}
