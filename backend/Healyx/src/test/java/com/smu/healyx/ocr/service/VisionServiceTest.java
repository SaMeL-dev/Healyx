package com.smu.healyx.ocr.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.exception.ExternalApiException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpEntity;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VisionServiceTest {

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private VisionService visionService;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(visionService, "visionApiKey", "test-api-key");
        ReflectionTestUtils.setField(visionService, "objectMapper", new ObjectMapper());
    }

    @Test
    @DisplayName("정상 응답 시 텍스트를 반환한다")
    void extractText_success() {
        // given
        String mockResponse = """
                {
                  "responses": [{
                    "textAnnotations": [
                      {"description": "처방전\\n환자명: 홍길동\\n약품: 타이레놀"}
                    ]
                  }]
                }
                """;
        when(restTemplate.postForObject(any(String.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockResponse);

        // when
        String result = visionService.extractText("base64encodedimage");

        // then
        assertThat(result).contains("처방전").contains("홍길동");
    }

    @Test
    @DisplayName("textAnnotations가 없으면 VISION_NO_TEXT 예외가 발생한다")
    void extractText_noText() {
        // given
        String mockResponse = """
                {
                  "responses": [{}]
                }
                """;
        when(restTemplate.postForObject(any(String.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockResponse);

        // when & then
        assertThatThrownBy(() -> visionService.extractText("base64encodedimage"))
                .isInstanceOf(ExternalApiException.class)
                .hasMessageContaining("다시 촬영");
    }

    @Test
    @DisplayName("API 호출 실패 시 VISION_API_ERROR 예외가 발생한다")
    void extractText_apiCallFails() {
        // given
        when(restTemplate.postForObject(any(String.class), any(HttpEntity.class), eq(String.class)))
                .thenThrow(new RuntimeException("Connection refused"));

        // when & then
        assertThatThrownBy(() -> visionService.extractText("base64encodedimage"))
                .isInstanceOf(ExternalApiException.class)
                .hasMessageContaining("접근할 수 없습니다");
    }
}