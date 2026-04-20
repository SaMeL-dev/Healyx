package com.smu.healyx.gpt.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.common.exception.ExternalApiException;
import com.smu.healyx.gpt.dto.GptChatRequest;
import com.smu.healyx.gpt.dto.GptChatResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class GptService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${api.gpt.key}")
    private String gptApiKey;

    private static final String GPT_URL = "https://api.openai.com/v1/chat/completions";
    private static final String MODEL = "gpt-5.4-mini";

    // 증상 분석에 사용할 HIRA 진료과목 코드 목록
    private static final String DEPARTMENT_CODES = """
            00:일반의, 01:내과, 02:신경과, 03:정신건강의학과, 04:피부과,
            05:외과, 06:흉부외과, 07:정형외과, 08:신경외과, 09:산부인과,
            10:소아청소년과, 11:안과, 12:이비인후과, 13:비뇨의학과,
            18:재활의학과, 20:가정의학과, 21:응급의학과, 24:치과
            """;

    /**
     * 증상 텍스트를 분석하여 HIRA 진료과목 코드(dgsbjtCd)를 추출합니다.
     * 입력 언어 제한 없음 (8개 언어 모두 지원).
     *
     * @return [0]: dgsbjtCd (예: "12"), [1]: 진료과 이름 (예: "이비인후과")
     */
    public String[] extractDepartmentCode(String symptom) {
        String systemPrompt = """
                You are a medical assistant helping foreign patients in Korea find the right hospital department.
                Analyze the patient's symptoms and return ONLY a valid JSON object.

                Available HIRA department codes:
                """ + DEPARTMENT_CODES + """

                Response format (JSON only, no explanation):
                {"dgsbjtCd":"01","departmentName":"내과"}

                If symptoms are unclear, return the most relevant department.
                """;

        GptChatRequest request = new GptChatRequest(
                MODEL,
                List.of(
                        new GptChatRequest.Message("system", systemPrompt),
                        new GptChatRequest.Message("user", symptom)
                ),
                100,
                0.0
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(gptApiKey);

        HttpEntity<GptChatRequest> entity = new HttpEntity<>(request, headers);

        try {
            GptChatResponse response = restTemplate.postForObject(
                    GPT_URL, entity, GptChatResponse.class);

            if (response == null || response.getFirstContent() == null) {
                throw new ExternalApiException("GPT_EMPTY_RESPONSE", "증상 분석 결과를 받지 못했습니다. 다시 시도해 주세요.");
            }

            return parseGptResult(response.getFirstContent());

        } catch (ExternalApiException e) {
            throw e;
        } catch (Exception e) {
            log.error("GPT API 호출 실패: {}", e.getMessage());
            throw new ExternalApiException("GPT_API_ERROR", "증상 분석 서비스에 일시적으로 접근할 수 없습니다. 다시 시도해 주세요.");
        }
    }

    /** GPT 응답 JSON에서 dgsbjtCd와 departmentName을 추출합니다. */
    private String[] parseGptResult(String content) {
        try {
            // GPT가 가끔 ```json ... ``` 형태로 감싸서 반환하는 경우 제거
            String cleaned = content.trim()
                    .replaceAll("(?s)```json\\s*", "")
                    .replaceAll("(?s)```\\s*", "")
                    .trim();

            JsonNode node = objectMapper.readTree(cleaned);
            String dgsbjtCd = node.path("dgsbjtCd").asText();
            String departmentName = node.path("departmentName").asText();

            if (dgsbjtCd.isBlank()) {
                log.warn("GPT 응답에서 dgsbjtCd 파싱 실패. 원본: {}", content);
                throw new ExternalApiException("GPT_PARSE_ERROR", "증상 분석 결과를 해석할 수 없습니다. 다시 시도해 주세요.");
            }

            log.debug("GPT 진료과 추출 완료: dgsbjtCd={}, 진료과={}", dgsbjtCd, departmentName);
            return new String[]{dgsbjtCd, departmentName};

        } catch (ExternalApiException e) {
            throw e;
        } catch (Exception e) {
            log.error("GPT 응답 파싱 실패. 원본: {}", content);
            throw new ExternalApiException("GPT_PARSE_ERROR", "증상 분석 결과를 해석할 수 없습니다. 다시 시도해 주세요.");
        }
    }
}
