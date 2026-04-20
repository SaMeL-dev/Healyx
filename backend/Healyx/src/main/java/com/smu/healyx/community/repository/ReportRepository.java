package com.smu.healyx.community.repository;

import com.smu.healyx.community.domain.Report;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ReportRepository extends JpaRepository<Report, Long> {
    List<Report> findByReporter_UserId(Long reporterId);
    List<Report> findByTargetTypeAndTargetId(String targetType, Long targetId);
    List<Report> findByStatus(String status);
}
