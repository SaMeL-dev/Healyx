package com.smu.healyx.cost.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class CostPredictResponse {

    /** 예측 결과 PK */
    private Long predictionId;

    /** LLM이 추출한 ICD-10 코드 (fallback 시 null) */
    private String icd10Code;

    /** 방문 유형: outpatient / inpatient */
    private String visitType;

    /** 최저 예상 비용 (원) */
    private int minCost;

    /** 최고 예상 비용 (원) */
    private int maxCost;

    /** 통화 단위 */
    private String currency;
}