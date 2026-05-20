package com.smu.healyx.cost.seed;

import com.smu.healyx.cost.domain.CostReference;
import com.smu.healyx.cost.repository.CostReferenceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@RequiredArgsConstructor
@Slf4j
public class CostReferenceSeeder implements CommandLineRunner {

    private final CostReferenceRepository costReferenceRepository;

    @Override
    @Transactional
    public void run(String... args) {
        seedDentalIcd10();
    }

    /**
     * 치과 ICD-10 외래(outpatient) 시드 데이터 적재
     * 출처: 2023년 상반기 건강보험 진료비통계지표(표) 시트 40(순위 1~50) + 시트 42(순위 51~100)
     * insurance_avg_cost = 건당요양급여비용 - 건당급여비
     * no_insurance_avg_cost = 건당요양급여비용
     * 입원(inpatient) 데이터: 시트 36·38 상위 100위 내 치과 코드 없음 → INSERT 불가 (미삽입)
     * 치과 fallback 행: 단가 산출 불가(설계 제1원칙) → 미삽입 (옵션 A 채택)
     */
    private void seedDentalIcd10() {
        // 시트 40, 순위 1 (line 1079)
        insertIfAbsent("K05", "치은염 및 치주질환", 15683, 51756);
        // 시트 40, 순위 6 (line 1084)
        insertIfAbsent("K02", "치아우식", 16262, 55816);
        // 시트 40, 순위 21 (line 1099)
        insertIfAbsent("K04", "치수 및 근단주위조직의 질환", 15440, 51901);
        // 시트 40, 순위 33 (line 1111)
        insertIfAbsent("K00", "치아의 발육 및 맹출 장애", 10305, 36974);
        // 시트 40, 순위 39 (line 1117)
        insertIfAbsent("K03", "치아경조직의 기타 질환", 16189, 54113);
        // 시트 40, 순위 42 (line 1120) — 보철·임플란트 포함으로 이상치, 원본 그대로 반영
        insertIfAbsent("K08", "치아 및 지지구조의 기타 장애", 113689, 381831);
        // 시트 42, 순위 63 (line 1151)
        insertIfAbsent("K01", "매몰치 및 매복치", 22484, 67578);
        // 시트 42, 순위 69 (line 1157)
        insertIfAbsent("K07", "치아얼굴이상[부정교합포함]", 13696, 42845);
        // 시트 42, 순위 88 (line 1176)
        insertIfAbsent("K12", "구내염 및 관련 병변", 5736, 21005);
    }

    private void insertIfAbsent(String icd10Code, String diseaseName,
                                int insuranceAvgCost, int noInsuranceAvgCost) {
        String visitType = "outpatient";
        if (costReferenceRepository.existsByIcd10CodeAndVisitType(icd10Code, visitType)) {
            log.info("cost_reference 시드 SKIP (기존 존재): {} {}", icd10Code, visitType);
            return;
        }
        CostReference entity = CostReference.builder()
                .icd10Code(icd10Code)
                .diseaseName(diseaseName)
                .visitType(visitType)
                .insuranceAvgCost(insuranceAvgCost)
                .noInsuranceAvgCost(noInsuranceAvgCost)
                .build();
        costReferenceRepository.save(entity);
        log.info("cost_reference 시드 INSERT: {} {}", icd10Code, visitType);
    }
}
