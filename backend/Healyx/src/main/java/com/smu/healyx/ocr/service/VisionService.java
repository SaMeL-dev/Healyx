package com.smu.healyx.ocr.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.exception.ExternalApiException;
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
public class VisionService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${api.vision.key}")
    private String visionApiKey;

    private static final String VISION_URL = "https://vision.googleapis.com/v1/images:annotate";

    /**
     * Base64 이미지에서 텍스트를 추출합니다 (TEXT_DETECTION).
     * 텍스트 미감지 시 ExternalApiException을 발생시킵니다.
     */
    public String extractText(String imageBase64) {
        // Vision API 요청 바디 구성
        Map<String, Object> requestBody = Map.of(
                "requests", List.of(Map.of(
                        "image", Map.of("content", imageBase64),
                        "features", List.of(Map.of("type", "TEXT_DETECTION"))
                ))
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        String url = VISION_URL + "?key=" + visionApiKey;

        String rawResponse;
        try {
            rawResponse = restTemplate.postForObject(url, entity, String.class);
        } catch (Exception e) {
            log.error("Google Vision API 호출 실패: {}", e.getMessage());
            throw new ExternalApiException("VISION_API_ERROR", "텍스트 인식 서비스에 일시적으로 접근할 수 없습니다. 잠시 후 다시 시도해 주세요.");
        }

        return parseText(rawResponse);
    }

    /** Vision API 응답에서 전체 텍스트를 추출합니다. */
    private String parseText(String rawResponse) {
        try {
            JsonNode root = objectMapper.readTree(rawResponse);
            JsonNode textAnnotations = root
                    .path("responses").get(0)
                    .path("textAnnotations");

            // textAnnotations[0].description에 전체 텍스트가 포함됩니다.
            if (textAnnotations.isMissingNode() || textAnnotations.isEmpty()) {
                log.warn("Vision API: 텍스트 미감지");
                throw new ExternalApiException("VISION_NO_TEXT", "텍스트를 인식할 수 없습니다. 이미지를 다시 촬영해 주세요.");
            }

            String text = textAnnotations.get(0).path("description").asText();
            log.debug("Vision OCR 추출 완료: {} 글자", text.length());
            return text;

        } catch (ExternalApiException e) {
            throw e;
        } catch (Exception e) {
            log.error("Vision API 응답 파싱 실패: {}", e.getMessage());
            throw new ExternalApiException("VISION_PARSE_ERROR", "텍스트 인식 결과를 처리할 수 없습니다. 다시 시도해 주세요.");
        }
    }
}