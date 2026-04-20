package com.smu.healyx.ocr.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import java.io.InputStream;
import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * 실제 Google Vision API 호출 통합 테스트
 * - VISION_API_KEY 환경변수 미설정 시 테스트를 건너뜁니다.
 */
class VisionServiceIntegrationTest {

    private VisionService visionService;

    private static final String API_KEY = System.getenv("VISION_API_KEY");

    @BeforeEach
    void setUp() {
        assumeTrue(API_KEY != null && !API_KEY.isBlank(), "VISION_API_KEY 환경변수가 설정되지 않아 테스트를 건너뜁니다.");
        System.out.println("setUp 통과 - VisionService 초기화 시작");
        visionService = new VisionService(new RestTemplate(), new ObjectMapper());
        ReflectionTestUtils.setField(visionService, "visionApiKey", API_KEY);
        System.out.println("setUp 완료");
    }

    @Test
    @DisplayName("[실제 API] 텍스트 이미지 → 텍스트 추출")
    void realApi_extractText() {
        // 'Hello HEALYX' 문자열을 담은 최소 PNG (1x1 흰 배경에 텍스트)
        // 실제 테스트 시에는 의료 문서 이미지의 Base64를 사용하세요.
        System.out.println("테스트 시작");
        String sampleBase64 = getSampleImageBase64();
        System.out.println("이미지 Base64 길이: " + (sampleBase64 != null ? sampleBase64.length() : "null"));

        String result = visionService.extractText(sampleBase64);
        System.out.println("추출된 텍스트: " + result);

        assertThat(result).isNotBlank();
    }

    /** 테스트용 샘플 이미지 Base64 (Google Vision 공식 샘플) */
    private String getSampleImageBase64() {
        try {
            InputStream is = getClass().getResourceAsStream("/test-image.png");
            byte[] imageBytes = is.readAllBytes();
            return Base64.getEncoder().encodeToString(imageBytes);
        } catch (Exception e) {
            assumeTrue(false, "이미지 로드 실패: " + e.getMessage());
            return null;
        }
    }
}