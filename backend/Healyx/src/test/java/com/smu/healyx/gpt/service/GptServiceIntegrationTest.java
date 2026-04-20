package com.smu.healyx.gpt.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * 실제 OpenAI API 호출 통합 테스트
 * - 서버 없이 API 키 유효성 및 응답 파싱을 검증합니다.
 * - CI 환경에서는 실행하지 않도록 주의하세요 (API 비용 발생).
 */
class GptServiceIntegrationTest {

    private GptService gptService;

    // 환경변수 GPT_API_KEY에서 키를 읽습니다. 설정되지 않으면 테스트를 건너뜁니다.
    private static final String API_KEY = System.getenv("GPT_API_KEY");

    @BeforeEach
    void setUp() {
        // GPT_API_KEY 환경변수가 없으면 테스트 전체를 건너뜁니다.
        assumeTrue(API_KEY != null && !API_KEY.isBlank(), "GPT_API_KEY 환경변수가 설정되지 않아 테스트를 건너뜁니다.");
        gptService = new GptService(new RestTemplate(), new ObjectMapper());
        org.springframework.test.util.ReflectionTestUtils.setField(gptService, "gptApiKey", API_KEY);
    }

    @Test
    @DisplayName("[실제 API] 한국어 증상 → 진료과 코드 추출")
    void realApi_korean() {
        String[] result = gptService.extractDepartmentCode("목이 아프고 열이 납니다");
        System.out.println("진료과 코드: " + result[0] + ", 이름: " + result[1]);

        assertThat(result[0]).isNotBlank();
        assertThat(result[1]).isNotBlank();
    }

    @Test
    @DisplayName("[실제 API] 영어 증상 → 진료과 코드 추출")
    void realApi_english() {
        String[] result = gptService.extractDepartmentCode("I have a severe headache and dizziness");
        System.out.println("진료과 코드: " + result[0] + ", 이름: " + result[1]);

        assertThat(result[0]).isNotBlank();
        assertThat(result[1]).isNotBlank();
    }

    @Test
    @DisplayName("[실제 API] 중국어 증상 → 진료과 코드 추출")
    void realApi_chinese() {
        String[] result = gptService.extractDepartmentCode("我肚子疼，感觉恶心想吐");
        System.out.println("진료과 코드: " + result[0] + ", 이름: " + result[1]);

        assertThat(result[0]).isNotBlank();
        assertThat(result[1]).isNotBlank();
    }
}