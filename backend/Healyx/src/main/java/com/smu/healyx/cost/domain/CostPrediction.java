package com.smu.healyx.cost.domain;

import com.smu.healyx.user.domain.User;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "cost_predictions")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class CostPrediction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "prediction_id")
    private Long predictionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "symptom_input", columnDefinition = "TEXT")
    private String symptomInput;

    @Column(name = "icd10_code", length = 10)
    private String icd10Code;

    @Column(name = "department", length = 50)
    private String department;

    @Column(name = "risk_level")
    private Integer riskLevel;

    @Column(name = "visit_type", length = 10)
    private String visitType;

    @Column(name = "min_cost")
    private Integer minCost;

    @Column(name = "max_cost")
    private Integer maxCost;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
    }
}