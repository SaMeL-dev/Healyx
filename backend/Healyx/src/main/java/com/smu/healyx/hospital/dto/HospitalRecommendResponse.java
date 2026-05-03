package com.smu.healyx.hospital.dto;

import com.smu.healyx.hira.dto.HospitalDto;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
@AllArgsConstructor
public class HospitalRecommendResponse {

    /** GPT Agent가 분석한 HIRA 진료과목 코드 (예: "01") */
    private String departmentCode;

    /** 진료과 이름 (예: "내과") */
    private String departmentName;

    /** GPT Agent가 추출한 ICD-10 코드 — 의료비 예측 모듈(COST)에서 활용 */
    private String icd10Code;

    /** HIRA API 기반 병원 목록 */
    private List<HospitalDto> hospitals;

    /** 조회된 총 병원 수 */
    private int totalCount;

    /** 반경 내 병원 존재 여부 */
    private boolean hasResult;

    /** 결과 없음 사유 — hasResult=false일 때만 값 존재 */
    private String emptyReason;
}