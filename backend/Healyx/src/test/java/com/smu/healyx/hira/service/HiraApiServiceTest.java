package com.smu.healyx.hira.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.hira.dto.HospitalDto;
import com.smu.healyx.hira.dto.HospitalSearchRequest;
import com.smu.healyx.hira.dto.HospitalSearchResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;
import static org.assertj.core.api.Assertions.assertThat;

/**
 * HIRA Open API 실제 연동 테스트
 *
 * Spring 컨텍스트 없이 실행 — DB/Redis 연결 불필요
 * 실제 HIRA API를 호출하므로 인터넷 연결이 필요합니다.
 * 일 10,000건 호출 제한에 유의하세요.
 */
@DisplayName("HIRA Open API 연동 테스트")
class HiraApiServiceTest {

    private HiraApiService hiraApiService;

    // ─── API 설정 (application-local.properties 값을 직접 입력) ───────────
    private static final String HIRA_URL = System.getenv("HIRA_API_URL");
    private static final String HIRA_KEY = System.getenv("HIRA_API_KEY");
    // ──────────────────────────────────────────────────────────────────────

    @BeforeEach
    void setUp() {
        hiraApiService = new HiraApiService(new RestTemplate(), new ObjectMapper());
        ReflectionTestUtils.setField(hiraApiService, "hiraApiUrl", HIRA_URL);
        ReflectionTestUtils.setField(hiraApiService, "hiraApiKey", HIRA_KEY);
    }

    // ─────────────────────────────────────────────────────────────
    // 테스트 1: 진료과 코드로 검색
    // ─────────────────────────────────────────────────────────────
    @Test
    @DisplayName("진료과 코드(내과 01)로 병원 5건 조회")
    void searchByDepartmentCode() {
        HospitalSearchRequest request = new HospitalSearchRequest();
        request.setDgsbjtCd("01"); // 내과
        request.setNumOfRows(5);

        HospitalSearchResponse response = hiraApiService.searchHospitals(request);

        printResult("진료과(내과) 검색", response);

        assertThat(response).isNotNull();
        assertThat(response.getHospitals()).isNotEmpty();
    }

    // ─────────────────────────────────────────────────────────────
    // 테스트 2: 위치 기반 검색 (서울 시청 반경 3km)
    // ─────────────────────────────────────────────────────────────
    @Test
    @DisplayName("위치 기반 검색 — 서울 시청 반경 3km")
    void searchByLocation() {
        HospitalSearchRequest request = new HospitalSearchRequest();
        request.setXPos("126.9780"); // 서울 시청 경도
        request.setYPos("37.5665");  // 서울 시청 위도
        request.setRadius("3");
        request.setNumOfRows(5);

        HospitalSearchResponse response = hiraApiService.searchHospitals(request);

        printResult("위치 기반(서울 시청 3km)", response);

        assertThat(response).isNotNull();
    }

    // ─────────────────────────────────────────────────────────────
    // 테스트 3: 진료과 + 종별코드 복합 검색
    // ─────────────────────────────────────────────────────────────
    @Test
    @DisplayName("내과(01) + 의원(31) 복합 검색")
    void searchByDepartmentAndType() {
        HospitalSearchRequest request = new HospitalSearchRequest();
        request.setDgsbjtCd("01"); // 내과
        request.setClCd("31");     // 의원
        request.setNumOfRows(5);

        HospitalSearchResponse response = hiraApiService.searchHospitals(request);

        printResult("내과 + 의원 복합 검색", response);

        assertThat(response).isNotNull();
        assertThat(response.getHospitals())
                .allMatch(h -> "의원".equals(h.getHospitalType()),
                        "모든 결과가 의원이어야 합니다.");
    }

    // ─────────────────────────────────────────────────────────────
    // 테스트 4: 위치 + 진료과 통합 검색 (GPT 연동 이후 주 시나리오)
    // ─────────────────────────────────────────────────────────────
    @Test
    @DisplayName("위치 + 진료과 통합 검색 — 실제 앱 시나리오")
    void searchByLocationAndDepartment() {
        HospitalSearchRequest request = new HospitalSearchRequest();
        request.setDgsbjtCd("01"); // 내과 (추후 GPT가 추출)
        request.setXPos("126.9780");
        request.setYPos("37.5665");
        request.setRadius("5");
        request.setNumOfRows(10);

        HospitalSearchResponse response = hiraApiService.searchHospitals(request);

        printResult("위치 + 진료과 통합 검색", response);

        assertThat(response).isNotNull();
    }

    // ─────────────────────────────────────────────────────────────
    // 진단 테스트: API 키 / 네트워크 상태 확인
    // ─────────────────────────────────────────────────────────────
    // ─────────────────────────────────────────────────────────────
    // 진단 테스트: API 키 / 네트워크 상태 확인
    // ─────────────────────────────────────────────────────────────
    @Test
    @DisplayName("[진단] 원시 HTTP 응답 출력 — 오류 발생 시 먼저 이 테스트 실행")
    void diagnoseRawApiResponse() {
        RestTemplate rt = new RestTemplate();

        // String이 아닌 URI 객체로 전달 → RestTemplate이 재인코딩하지 않음
        java.net.URI uri = java.net.URI.create(
                HIRA_URL + "/getHospBasisList?serviceKey=" + HIRA_KEY
        );

        try {
            String raw = rt.getForObject(uri, String.class);
            System.out.println("[진단] 원시 응답:\n" + raw);
        } catch (Exception e) {
            System.err.println("[진단] HTTP 오류: " + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 결과 출력 헬퍼
    // ─────────────────────────────────────────────────────────────
    private void printResult(String title, HospitalSearchResponse response) {
        System.out.println("\n============================");
        System.out.println(" [" + title + "]");
        System.out.printf(" 총 %d건 중 %d건 조회 (페이지 %d)%n",
                response.getTotalCount(), response.getHospitals().size(), response.getPageNo());
        System.out.println("============================");
        for (HospitalDto h : response.getHospitals()) {
            System.out.printf(" %-8s | %-20s | %s%n",
                    h.getHospitalType(), h.getHospitalName(), h.getAddress());
            System.out.printf("           위도: %-10s 경도: %-10s 전화: %s%n",
                    h.getLatitude(), h.getLongitude(), h.getTelephone());
        }
        System.out.println();
    }
}