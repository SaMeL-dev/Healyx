package com.smu.healyx.translation.repository;

import com.smu.healyx.translation.domain.MedicalTranslation;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface MedicalTranslationRepository extends JpaRepository<MedicalTranslation, Long> {
    List<MedicalTranslation> findByUser_UserId(Long userId);
    List<MedicalTranslation> findByUserIsNull();
}
