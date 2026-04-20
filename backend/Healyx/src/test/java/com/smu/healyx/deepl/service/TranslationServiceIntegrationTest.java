package com.smu.healyx.deepl.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.deepl.dto.TranslationResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

/**
 * 실제 DeepL API 호출 통합 테스트
 * - DEEPL_API_KEY 환경변수 미설정 시 테스트를 건너뜁니다.
 * - 실행 방법: 환경변수 DEEPL_API_KEY=<키값> 을 설정한 후 테스트를 실행하세요.
 */
class TranslationServiceIntegrationTest {

    private TranslationService translationService;

    private static final String API_KEY = System.getenv("DEEPL_API_KEY");

    // 번역 원문 (한국어 의료 문서 예시)
    private static final String SAMPLE_TEXT = "두통이 심하고 열이 38도 이상입니다. 타이레놀을 복용했으나 나아지지 않습니다.";

    @BeforeEach
    void setUp() {
        assumeTrue(API_KEY != null && !API_KEY.isBlank(), "DEEPL_API_KEY 환경변수가 설정되지 않아 테스트를 건너뜁니다.");
        translationService = new TranslationService(new RestTemplate(), new ObjectMapper());
        ReflectionTestUtils.setField(translationService, "deeplApiKey", API_KEY);
    }

    @Test
    @DisplayName("[실제 API] 한국어 → 영어 번역")
    void realApi_koreanToEnglish() {
        TranslationResponse result = translationService.translate(SAMPLE_TEXT, "en");

        System.out.println("원문: " + SAMPLE_TEXT);
        System.out.println("번역(EN): " + result.getTranslatedText());
        System.out.println("감지된 원문 언어: " + result.getDetectedSourceLanguage());

        assertThat(result.getTranslatedText()).isNotBlank();
        assertThat(result.getDetectedSourceLanguage()).isEqualTo("KO");
        assertThat(result.getTargetLanguage()).isEqualTo("EN-US");
    }

    @Test
    @DisplayName("[실제 API] 한국어 → 중국어 번역")
    void realApi_koreanToChinese() {
        TranslationResponse result = translationService.translate(SAMPLE_TEXT, "zh");

        System.out.println("번역(ZH): " + result.getTranslatedText());

        assertThat(result.getTranslatedText()).isNotBlank();
        assertThat(result.getTargetLanguage()).isEqualTo("ZH");
    }

    @Test
    @DisplayName("[실제 API] 한국어 → 베트남어 번역")
    void realApi_koreanToVietnamese() {
        TranslationResponse result = translationService.translate(SAMPLE_TEXT, "vi");

        System.out.println("번역(VI): " + result.getTranslatedText());

        assertThat(result.getTranslatedText()).isNotBlank();
        assertThat(result.getTargetLanguage()).isEqualTo("VI");
    }

    @Test
    @DisplayName("[실제 API] 한국어 → 태국어 번역")
    void realApi_koreanToThai() {
        TranslationResponse result = translationService.translate(SAMPLE_TEXT, "th");

        System.out.println("번역(TH): " + result.getTranslatedText());

        assertThat(result.getTranslatedText()).isNotBlank();
        assertThat(result.getTargetLanguage()).isEqualTo("TH");
    }

    @Test
    @DisplayName("[실제 API] 한국어 → 일본어 번역")
    void realApi_koreanToJapanese() {
        TranslationResponse result = translationService.translate(SAMPLE_TEXT, "ja");

        System.out.println("번역(JA): " + result.getTranslatedText());

        assertThat(result.getTranslatedText()).isNotBlank();
        assertThat(result.getTargetLanguage()).isEqualTo("JA");
    }

    @Test
    @DisplayName("[실제 API] 모든 지원 언어 번역 결과 출력")
    void realApi_allSupportedLanguages() {
        String[] langCodes = {"en", "zh", "vi", "th", "ja"};

        for (String lang : langCodes) {
            TranslationResponse result = translationService.translate(SAMPLE_TEXT, lang);

            System.out.printf("[%s → %s] %s%n", "ko", result.getTargetLanguage(), result.getTranslatedText());

            assertThat(result.getTranslatedText()).isNotBlank();
        }
    }
}