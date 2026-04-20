package com.smu.healyx.hospital.domain;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "hospital_departments")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class HospitalDepartment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "dept_id")
    private Long deptId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "hospital_id", nullable = false)
    private Hospital hospital;

    @Column(name = "department_name", nullable = false, length = 50)
    private String departmentName;
}