package com.smu.healyx.agent.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;

/** Flutter → Agent 단일 통합 요청 DTO */
@Getter
@NoArgsConstructor
public class HospitalAssistantRequest {

    /** 증상 텍스트 (6개 언어 모두 허용) */
    @NotBlank(message = "증상을 입력해 주세요.")
    private String symptom;

    /** 위험도: 1(경증) ~ 5(응급) */
    @Min(value = 1, message = "위험도는 1 이상이어야 합니다.")
    @Max(value = 5, message = "위험도는 5 이하여야 합니다.")
    private int riskLevel;

    /** 사용자 위도 (Flutter GPS) */
    @NotNull(message = "위도를 입력해 주세요.")
    private Double latitude;

    /** 사용자 경도 (Flutter GPS) */
    @NotNull(message = "경도를 입력해 주세요.")
    private Double longitude;

    public static HospitalAssistantRequest of(String symptom, int riskLevel, Double latitude, Double longitude) {
        HospitalAssistantRequest request = new HospitalAssistantRequest();
        request.symptom = symptom;
        request.riskLevel = riskLevel;
        request.latitude = latitude;
        request.longitude = longitude;
        return request;
    }

    // 나이·성별·보험 가입 여부는 JWT → userId → DB 조회로 획득 (HospitalAgentController 참고)
}
