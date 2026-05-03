package com.smu.healyx.hospital.service;

import com.smu.healyx.agent.dto.HospitalAssistantRequest;
import com.smu.healyx.agent.dto.HospitalAssistantResponse;
import com.smu.healyx.agent.service.HospitalAgentService;
import com.smu.healyx.hira.dto.HospitalSearchResponse;
import com.smu.healyx.hospital.dto.HospitalRecommendRequest;
import com.smu.healyx.hospital.dto.HospitalRecommendResponse;
import com.smu.healyx.user.dto.UserProfileDto;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class HospitalRecommendService {

    private final HospitalAgentService hospitalAgentService;

    /**
     * AI Agent를 통해 증상을 분석하고 HIRA API 기반으로 병원을 추천합니다.
     *
     * - 진료과 결정: GPT Agent가 증상을 분석하여 HIRA dgsbjtCd 추출
     * - 위험도(riskLevel): 사용자 슬라이더 입력값 → Agent 내부에서 clCd·반경으로 변환
     * - ICD-10 코드: GPT Agent가 동시 추출 → 의료비 예측(COST) 모듈에서 활용
     */
    public HospitalRecommendResponse recommend(
            HospitalRecommendRequest request, UserProfileDto userProfile) {

        HospitalAssistantRequest agentRequest = buildAgentRequest(request);
        HospitalAssistantResponse agentResponse =
                hospitalAgentService.run(agentRequest, userProfile);

        HospitalSearchResponse searchResponse = agentResponse.getHospitals();
        boolean hasResult = searchResponse != null
                && searchResponse.getHospitals() != null
                && !searchResponse.getHospitals().isEmpty();

        String emptyReason = hasResult ? null :
                agentResponse.getDepartmentName()
                + " 진료과 병원을 찾을 수 없습니다. 증상을 다시 확인해 주세요.";

        return HospitalRecommendResponse.builder()
                .departmentCode(agentResponse.getDepartmentCode())
                .departmentName(agentResponse.getDepartmentName())
                .icd10Code(agentResponse.getIcd10Code())
                .hospitals(hasResult ? searchResponse.getHospitals() : List.of())
                .totalCount(hasResult ? searchResponse.getTotalCount() : 0)
                .hasResult(hasResult)
                .emptyReason(emptyReason)
                .build();
    }

    /**
     * HospitalRecommendRequest → HospitalAssistantRequest 변환.
     * riskLevel이 null이면 getEffectiveRiskLevel()이 기본값 2 반환.
     */
    private HospitalAssistantRequest buildAgentRequest(HospitalRecommendRequest request) {
        return HospitalAssistantRequest.of(
                request.getSymptom(),
                request.getEffectiveRiskLevel(),
                request.getLatitude(),
                request.getLongitude()
        );
    }
}