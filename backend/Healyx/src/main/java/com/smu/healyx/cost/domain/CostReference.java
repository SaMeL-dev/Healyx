package com.smu.healyx.cost.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "cost_reference", indexes = {
        @Index(name = "idx_costref_icd_visit",     columnList = "icd10_code, visit_type"),
        @Index(name = "idx_costref_disease_visit",  columnList = "disease_name, visit_type")
})
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class CostReference {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "cost_id")
    private Long costId;

    @Column(name = "icd10_code", length = 10)
    private String icd10Code;

    @Column(name = "disease_name", length = 100)
    private String diseaseName;

    @Column(name = "visit_type", nullable = false, length = 10)
    private String visitType;

    @Column(name = "insurance_avg_cost", nullable = false)
    private int insuranceAvgCost;

    @Column(name = "no_insurance_avg_cost", nullable = false)
    private int noInsuranceAvgCost;
}