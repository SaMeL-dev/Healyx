package com.smu.healyx.gpt.dto;

import lombok.Builder;
import lombok.Getter;

/** 증상 분석 응답 DTO */
@Getter
@Builder
public class SymptomAnalysisResponse {

    /** HIRA 진료과목 코드 (예: "12") */
    private String dgsbjtCd;

    /** 진료과 이름 (예: "이비인후과") */
    private String departmentName;
}