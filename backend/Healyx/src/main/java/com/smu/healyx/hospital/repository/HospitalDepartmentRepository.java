package com.smu.healyx.hospital.repository;

import com.smu.healyx.hospital.domain.HospitalDepartment;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface HospitalDepartmentRepository extends JpaRepository<HospitalDepartment, Long> {
    List<HospitalDepartment> findByHospital_HospitalId(Long hospitalId);
}