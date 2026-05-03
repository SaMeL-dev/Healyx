package com.smu.healyx.ocr.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.exception.ExternalApiException;
import com.smu.healyx.translation.dto.TextBlock;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
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

    /**
     * Base64 이미지에서 텍스트 블록(원문 + 바운딩박스)을 추출합니다 (DOCUMENT_TEXT_DETECTION).
     * 오버레이 번역 기능에 사용됩니다.
     */
    public List<TextBlock> extractTextBlocks(String imageBase64) {
        Map<String, Object> requestBody = Map.of(
                "requests", List.of(Map.of(
                        "image", Map.of("content", imageBase64),
                        "features", List.of(Map.of("type", "DOCUMENT_TEXT_DETECTION"))
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

        return parseTextBlocks(rawResponse);
    }

    /** DOCUMENT_TEXT_DETECTION 응답에서 문단별 텍스트 블록을 파싱합니다. */
    private List<TextBlock> parseTextBlocks(String rawResponse) {
        try {
            JsonNode root = objectMapper.readTree(rawResponse);
            JsonNode pages = root.path("responses").get(0)
                    .path("fullTextAnnotation").path("pages");

            if (pages.isMissingNode() || pages.isEmpty()) {
                throw new ExternalApiException("VISION_NO_TEXT", "텍스트를 인식할 수 없습니다. 이미지를 다시 촬영해 주세요.");
            }

            List<TextBlock> result = new ArrayList<>();
            for (JsonNode block : pages.get(0).path("blocks")) {
                for (JsonNode paragraph : block.path("paragraphs")) {
                    String text = reconstructText(paragraph);
                    if (text.isBlank()) continue;

                    int[] bbox = extractBbox(paragraph.path("boundingBox"));
                    result.add(TextBlock.builder()
                            .originalText(text)
                            .x(bbox[0]).y(bbox[1])
                            .width(bbox[2]).height(bbox[3])
                            .build());
                }
            }

            if (result.isEmpty()) {
                throw new ExternalApiException("VISION_NO_TEXT", "텍스트를 인식할 수 없습니다. 이미지를 다시 촬영해 주세요.");
            }

            log.debug("Vision DOCUMENT_TEXT_DETECTION 완료: {}개 블록 추출", result.size());
            return result;

        } catch (ExternalApiException e) {
            throw e;
        } catch (Exception e) {
            log.error("Vision API 응답 파싱 실패: {}", e.getMessage());
            throw new ExternalApiException("VISION_PARSE_ERROR", "텍스트 인식 결과를 처리할 수 없습니다. 다시 시도해 주세요.");
        }
    }

    /** 문단 내 words → symbols를 순서대로 이어 붙여 텍스트를 복원합니다. */
    private String reconstructText(JsonNode paragraph) {
        StringBuilder sb = new StringBuilder();
        for (JsonNode word : paragraph.path("words")) {
            for (JsonNode symbol : word.path("symbols")) {
                sb.append(symbol.path("text").asText());
                String breakType = symbol.path("property").path("detectedBreak").path("type").asText("");
                switch (breakType) {
                    case "SPACE", "SURE_SPACE" -> sb.append(" ");
                    case "EOL_SURE_SPACE", "LINE_BREAK" -> sb.append("\n");
                    case "HYPHEN" -> sb.append("-");
                }
            }
        }
        return sb.toString().strip();
    }

    /** boundingBox.vertices에서 (x, y, width, height)를 계산합니다. */
    private int[] extractBbox(JsonNode boundingBox) {
        JsonNode vertices = boundingBox.path("vertices");
        int minX = Integer.MAX_VALUE, minY = Integer.MAX_VALUE;
        int maxX = 0, maxY = 0;
        for (JsonNode v : vertices) {
            int x = v.path("x").asInt(0);
            int y = v.path("y").asInt(0);
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
        }
        return new int[]{minX, minY, maxX - minX, maxY - minY};
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