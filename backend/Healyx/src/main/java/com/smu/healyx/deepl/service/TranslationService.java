package com.smu.healyx.deepl.service;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.exception.ExternalApiException;
import com.smu.healyx.deepl.dto.TranslationResponse;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class TranslationService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${api.deepl.key}")
    private String deeplApiKey;

    private static final String DEEPL_URL = "https://api-free.deepl.com/v2/translate";

    private static final Map<String, String> LANGUAGE_MAP = Map.of(
            "ko", "KO",
            "zh", "ZH",
            "vi", "VI",
            "th", "TH",
            "en", "EN-US",
            "ja", "JA"
    );

    /**
     * 텍스트를 지정한 언어로 번역합니다.
     * 지원 언어: ko, zh, vi, th, en, ja
     */
    public TranslationResponse translate(String text, String targetLanguage) {
        String deeplTargetLang = LANGUAGE_MAP.get(targetLanguage);
        if (deeplTargetLang == null) {
            throw new ExternalApiException("DEEPL_UNSUPPORTED_LANG", "지원하지 않는 언어 코드입니다: " + targetLanguage);
        }
        Map<String, Object> requestBody = Map.of(
                "text", List.of(text),
                "target_lang", deeplTargetLang
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Authorization", "DeepL-Auth-Key " + deeplApiKey);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        String rawResponse;
        try {
            rawResponse = restTemplate.postForObject(DEEPL_URL, entity, String.class);
        } catch (Exception e) {
            log.error("DeepL API 호출 실패: {}", e.getMessage());
            throw new ExternalApiException("DEEPL_API_ERROR", "번역 서비스가 일시적으로 이용 불가합니다. 잠시 후 다시 시도해 주세요.");
        }

        return parseResponse(rawResponse, deeplTargetLang);
    }

    /** DeepL 응답 JSON을 파싱하여 TranslationResponse를 반환합니다. */
    private TranslationResponse parseResponse(String rawResponse, String deeplTargetLang) {
        try {
            DeeplApiResponse response = objectMapper.readValue(rawResponse, DeeplApiResponse.class);

            if (response.getTranslations() == null || response.getTranslations().isEmpty()) {
                log.warn("DeepL API: 번역 결과 없음");
                throw new ExternalApiException("DEEPL_EMPTY_RESPONSE", "번역 결과를 받지 못했습니다. 다시 시도해 주세요.");
            }

            DeeplApiResponse.Translation translation = response.getTranslations().get(0);
            log.debug("DeepL 번역 완료: 감지언어={}, 대상언어={}", translation.getDetectedSourceLanguage(), deeplTargetLang);

            return TranslationResponse.builder()
                    .translatedText(translation.getText())
                    .detectedSourceLanguage(translation.getDetectedSourceLanguage())
                    .targetLanguage(deeplTargetLang)
                    .build();

        } catch (ExternalApiException e) {
            throw e;
        } catch (Exception e) {
            log.error("DeepL 응답 파싱 실패: {}", e.getMessage());
            throw new ExternalApiException("DEEPL_PARSE_ERROR", "번역 결과를 처리할 수 없습니다. 다시 시도해 주세요.");
        }
    }

    /** DeepL API 응답 구조 매핑용 내부 DTO */
    @Getter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class DeeplApiResponse {

        private List<Translation> translations;

        @Getter
        @NoArgsConstructor
        @JsonIgnoreProperties(ignoreUnknown = true)
        static class Translation {

            private String text;

            @JsonProperty("detected_source_language")
            private String detectedSourceLanguage;
        }
    }
}
