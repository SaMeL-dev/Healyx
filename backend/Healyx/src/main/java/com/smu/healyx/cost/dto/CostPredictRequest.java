package com.smu.healyx.cost.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class CostPredictRequest {

    /**
     * 병원 추천 API 응답에서 전달받은 ICD-10 코드.
     * icd10Code 또는 departmentName 중 하나 이상 필수.
     */
    private String icd10Code;

    /**
     * ICD-10 매칭 실패 시 fallback용 진료과명 (한국어).
     * icd10Code 또는 departmentName 중 하나 이상 필수.
     */
    private String departmentName;

    /** 위험도 1~5 (병원 추천 요청 시 사용한 값과 동일) */
    @NotNull(message = "위험도는 필수 입력값입니다.")
    @Min(value = 1, message = "위험도는 1~5 사이 값이어야 합니다.")
    @Max(value = 5, message = "위험도는 1~5 사이 값이어야 합니다.")
    private Integer riskLevel;

    /**
     * 병원 카드의 clCd (HIRA 종별코드).
     * 없으면 병원종별 보정 1.0 적용.
     */
    private String hospitalType;

    /**
     * 비로그인 또는 프로필 미설정 시 전달.
     * 로그인 시 DB 프로필 우선 적용.
     */
    private Integer age;

    /**
     * 성별 M/F.
     * 비로그인 또는 프로필 미설정 시 전달.
     * 로그인 시 DB 프로필 우선 적용.
     */
    private String gender;

    /**
     * 건강보험 가입 여부.
     * 비로그인 또는 프로필 미설정 시 전달.
     * 로그인 시 DB 프로필 우선 적용. 미전달 시 false.
     */
    private Boolean hasHealthInsurance;

    /** icd10Code, departmentName 둘 다 없으면 true */
    public boolean hasNoCostBasis() {
        return (icd10Code == null || icd10Code.isBlank())
                && (departmentName == null || departmentName.isBlank());
    }
}