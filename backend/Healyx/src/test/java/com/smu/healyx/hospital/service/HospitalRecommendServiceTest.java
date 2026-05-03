package com.smu.healyx.hospital.service;

import com.smu.healyx.agent.dto.HospitalAssistantRequest;
import com.smu.healyx.agent.dto.HospitalAssistantResponse;
import com.smu.healyx.agent.service.HospitalAgentService;
import com.smu.healyx.hira.dto.HospitalDto;
import com.smu.healyx.hira.dto.HospitalSearchResponse;
import com.smu.healyx.hospital.dto.HospitalRecommendRequest;
import com.smu.healyx.hospital.dto.HospitalRecommendResponse;
import com.smu.healyx.user.dto.UserProfileDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("HospitalRecommendService 단위 테스트")
class HospitalRecommendServiceTest {

    @Mock
    private HospitalAgentService hospitalAgentService;

    private HospitalRecommendService hospitalRecommendService;

    private UserProfileDto guestProfile;

    @BeforeEach
    void setUp() {
        hospitalRecommendService = new HospitalRecommendService(hospitalAgentService);
        guestProfile = UserProfileDto.guestDefault();
    }

    @Test
    @DisplayName("정상 요청 시 Agent 응답을 그대로 매핑하고 hasResult=true를 반환한다")
    void recommend_normalRequest_mapsAgentResponseCorrectly() {
        HospitalRecommendRequest request = buildRequest("목이 아파요", 2);

        when(hospitalAgentService.run(any(HospitalAssistantRequest.class), any(UserProfileDto.class)))
                .thenReturn(agentResponse("이비인후과", hospital("A병원", 500), hospital("B병원", 1000)));

        HospitalRecommendResponse response =
                hospitalRecommendService.recommend(request, guestProfile);

        assertThat(response.getDepartmentName()).isEqualTo("이비인후과");
        assertThat(response.getDepartmentCode()).isEqualTo("01");
        assertThat(response.getIcd10Code()).isEqualTo("J06.9");
        assertThat(response.isHasResult()).isTrue();
        assertThat(response.getHospitals()).hasSize(2);
        assertThat(response.getHospitals().get(0).getHospitalName()).isEqualTo("A병원");
        assertThat(response.getEmptyReason()).isNull();
    }

    @Test
    @DisplayName("riskLevel 미전달 시 기본값(2)으로 Agent를 호출한다")
    void recommend_withNullRiskLevel_defaultsToTwo() {
        HospitalRecommendRequest request = buildRequest("배가 아파요", null);

        when(hospitalAgentService.run(any(HospitalAssistantRequest.class), any(UserProfileDto.class)))
                .thenReturn(agentResponse("내과", hospital("C병원", 300)));

        hospitalRecommendService.recommend(request, guestProfile);

        ArgumentCaptor<HospitalAssistantRequest> captor =
                ArgumentCaptor.forClass(HospitalAssistantRequest.class);
        verify(hospitalAgentService).run(captor.capture(), any(UserProfileDto.class));

        assertThat(captor.getValue().getRiskLevel()).isEqualTo(2);
        assertThat(captor.getValue().getSymptom()).isEqualTo("배가 아파요");
        assertThat(captor.getValue().getLatitude()).isEqualTo(37.5665);
        assertThat(captor.getValue().getLongitude()).isEqualTo(126.9780);
    }

    @Test
    @DisplayName("Agent 결과가 비어 있으면 hasResult=false와 emptyReason을 반환한다")
    void recommend_emptyAgentResult_returnsEmptyReason() {
        HospitalRecommendRequest request = buildRequest("증상", 3);

        when(hospitalAgentService.run(any(HospitalAssistantRequest.class), any(UserProfileDto.class)))
                .thenReturn(agentResponse("이비인후과"));

        HospitalRecommendResponse response =
                hospitalRecommendService.recommend(request, guestProfile);

        assertThat(response.isHasResult()).isFalse();
        assertThat(response.getHospitals()).isEmpty();
        assertThat(response.getTotalCount()).isEqualTo(0);
        assertThat(response.getEmptyReason())
                .isEqualTo("이비인후과 진료과 병원을 찾을 수 없습니다. 증상을 다시 확인해 주세요.");
    }

    // ── 헬퍼 메서드 ──────────────────────────────────────────────────

    private HospitalRecommendRequest buildRequest(String symptom, Integer riskLevel) {
        HospitalRecommendRequest request = new HospitalRecommendRequest();
        ReflectionTestUtils.setField(request, "symptom", symptom);
        ReflectionTestUtils.setField(request, "latitude", 37.5665);
        ReflectionTestUtils.setField(request, "longitude", 126.9780);
        ReflectionTestUtils.setField(request, "riskLevel", riskLevel);
        return request;
    }

    private HospitalAssistantResponse agentResponse(String department, HospitalDto... hospitals) {
        return HospitalAssistantResponse.builder()
                .departmentCode("01")
                .departmentName(department)
                .icd10Code("J06.9")
                .hospitals(HospitalSearchResponse.builder()
                        .hospitals(List.of(hospitals))
                        .pageNo(1)
                        .numOfRows(hospitals.length)
                        .totalCount(hospitals.length)
                        .build())
                .build();
    }

    private HospitalDto hospital(String name, int distanceMeter) {
        return HospitalDto.builder()
                .ykiho(name)
                .hospitalName(name)
                .address("서울시")
                .telephone("02-0000-0000")
                .longitude(126.9780)
                .latitude(37.5665)
                .distance(distanceMeter)
                .hospitalType("병원")
                .foreignCertified(false)
                .build();
    }
}