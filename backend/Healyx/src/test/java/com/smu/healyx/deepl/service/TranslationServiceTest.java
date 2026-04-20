package com.smu.healyx.deepl.service;

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
class TranslationServiceTest {

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private TranslationService translationService;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(translationService, "deeplApiKey", "test-api-key");
        ReflectionTestUtils.setField(translationService, "objectMapper", new ObjectMapper());
    }

    @Test
    @DisplayName("한국어 텍스트를 영어로 번역하면 번역 결과를 반환한다")
    void translate_koreanToEnglish_success() {
        // given
        String mockResponse = """
                {
                  "translations": [
                    {
                      "detected_source_language": "KO",
                      "text": "I have a severe headache and fever."
                    }
                  ]
                }
                """;
        when(restTemplate.postForObject(any(String.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockResponse);

        // when
        var result = translationService.translate("두통이 심하고 열이 납니다.", "en");

        // then
        assertThat(result.getTranslatedText()).isEqualTo("I have a severe headache and fever.");
        assertThat(result.getDetectedSourceLanguage()).isEqualTo("KO");
        assertThat(result.getTargetLanguage()).isEqualTo("EN-US");
    }

    @Test
    @DisplayName("영어 텍스트를 일본어로 번역하면 번역 결과를 반환한다")
    void translate_englishToJapanese_success() {
        // given
        String mockResponse = """
                {
                  "translations": [
                    {
                      "detected_source_language": "EN",
                      "text": "頭痛と発熱があります。"
                    }
                  ]
                }
                """;
        when(restTemplate.postForObject(any(String.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockResponse);

        // when
        var result = translationService.translate("I have a headache and fever.", "ja");

        // then
        assertThat(result.getTranslatedText()).isEqualTo("頭痛と発熱があります。");
        assertThat(result.getTargetLanguage()).isEqualTo("JA");
    }

    @Test
    @DisplayName("translations 배열이 비어있으면 DEEPL_EMPTY_RESPONSE 예외가 발생한다")
    void translate_emptyTranslations_throwsException() {
        // given
        String mockResponse = """
                {
                  "translations": []
                }
                """;
        when(restTemplate.postForObject(any(String.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockResponse);

        // when & then
        assertThatThrownBy(() -> translationService.translate("안녕하세요", "en"))
                .isInstanceOf(ExternalApiException.class)
                .hasMessageContaining("다시 시도");
    }

    @Test
    @DisplayName("DeepL API 호출 실패 시 DEEPL_API_ERROR 예외가 발생한다")
    void translate_apiCallFails_throwsException() {
        // given
        when(restTemplate.postForObject(any(String.class), any(HttpEntity.class), eq(String.class)))
                .thenThrow(new RuntimeException("Connection refused"));

        // when & then
        assertThatThrownBy(() -> translationService.translate("안녕하세요", "en"))
                .isInstanceOf(ExternalApiException.class)
                .hasMessageContaining("이용 불가");
    }

    @Test
    @DisplayName("지원하지 않는 언어 코드 입력 시 DEEPL_UNSUPPORTED_LANG 예외가 발생한다")
    void translate_unsupportedLanguage_throwsException() {
        // when & then
        assertThatThrownBy(() -> translationService.translate("Hello", "uz"))
                .isInstanceOf(ExternalApiException.class)
                .hasMessageContaining("지원하지 않는 언어 코드");
    }

    @Test
    @DisplayName("DeepL 응답 JSON이 잘못된 형식이면 DEEPL_PARSE_ERROR 예외가 발생한다")
    void translate_malformedResponse_throwsException() {
        // given
        String mockResponse = "{ invalid json }";
        when(restTemplate.postForObject(any(String.class), any(HttpEntity.class), eq(String.class)))
                .thenReturn(mockResponse);

        // when & then
        assertThatThrownBy(() -> translationService.translate("안녕하세요", "en"))
                .isInstanceOf(ExternalApiException.class)
                .hasMessageContaining("처리할 수 없습니다");
    }
}