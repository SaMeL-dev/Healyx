package com.smu.healyx.agent.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smu.healyx.agent.dto.HospitalAssistantRequest;
import com.smu.healyx.agent.dto.HospitalAssistantResponse;
import com.smu.healyx.common.exception.ExternalApiException;
import com.smu.healyx.gpt.dto.GptChatRequest;
import com.smu.healyx.gpt.dto.GptChatResponse;
import com.smu.healyx.gpt.dto.GptTool;
import com.smu.healyx.gpt.dto.GptToolCall;
import com.smu.healyx.gpt.service.GptService;
import com.smu.healyx.hira.dto.HospitalDto;
import com.smu.healyx.hira.dto.HospitalSearchRequest;
import com.smu.healyx.hira.dto.HospitalSearchResponse;
import com.smu.healyx.hira.service.HiraApiService;
import com.smu.healyx.hospital.domain.ForeignCertifiedHospital;
import com.smu.healyx.hospital.repository.ForeignCertifiedHospitalRepository;
import com.smu.healyx.user.dto.UserProfileDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * OpenAI Function Calling 기반 병원 탐색 AI Agent.
 *
 * 역할 분담:
 *   GPT    → 증상을 분석하여 HIRA 진료과목 코드(dgsbjtCd) 결정
 *   서버   → 위험도(1-5)를 병원 종별 범위(clCd 목록)·반경으로 변환,
 *            clCd별 HIRA API 다중 호출 후 병합·중복 제거
 *
 * Agent Loop:
 *   1. GPT → search_hospitals(dgsbjtCd) + extract_icd10_code 호출
 *   2. 서버 → 각 Tool 실행 → 결과를 대화 히스토리에 추가
 *   3. 두 Tool 완료 시 Loop 종료 → 통합 응답 반환
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class HospitalAgentService {

    private final GptService gptService;
    private final HiraApiService hiraApiService;
    private final ObjectMapper objectMapper;
    private final
    ForeignCertifiedHospitalRepository foreignCertifiedHospitalRepository;

    private static final String AGENT_MODEL = "gpt-4o";
    private static final int MAX_ITERATIONS = 6;

    private static final String TOOL_SEARCH_HOSPITALS = "search_hospitals";
    private static final String TOOL_EXTRACT_ICD10    = "extract_icd10_code";

    /**
     * 위험도별 병원 종별 범위 (낮은 단계일수록 더 많은 종별 포함)
     *
     *   1: 의원 ~ 상급종합 [31, 21, 11, 01]
     *   2: 의원 ~ 상급종합 [31, 21, 11, 01]
     *   3: 병원 ~ 상급종합 [21, 11, 01]
     *   4: 종합병원 ~ 상급종합 [11, 01]
     *   5: 상급종합만 [01]
     */
    private static final Map<Integer, List<String>> RISK_TO_CL_CDS = Map.of(
            1, List.of("31", "21", "11", "01"),
            2, List.of("31", "21", "11", "01"),
            3, List.of("21", "11", "01"),
            4, List.of("11", "01"),
            5, List.of("01")
    );

    /** 위험도별 검색 반경 (m): 1~2단계 3km, 3~5단계 15km */
    private static final Map<Integer, Integer> RISK_TO_RADIUS = Map.of(
            1, 3000,
            2, 3000,
            3, 15000,
            4, 15000,
            5, 15000
    );

    public HospitalAssistantResponse run(HospitalAssistantRequest req, UserProfileDto userProfile) {
        List<GptChatRequest.Message> messages = buildInitialMessages(req, userProfile);
        List<GptTool> tools = buildTools();

        String departmentCode    = null;
        String departmentName    = null;
        HospitalSearchResponse hospitals = null;
        String icd10Code         = null;

        for (int i = 0; i < MAX_ITERATIONS; i++) {
            boolean needMore  = (hospitals == null || icd10Code == null);
            String toolChoice = needMore ? "required" : "auto";

            GptChatRequest chatReq = new GptChatRequest(
                    AGENT_MODEL, messages, 512, 0.0, tools, toolChoice);

            GptChatResponse response = gptService.callChatCompletion(chatReq);
            String finishReason = response.getFinishReason();
            log.debug("Agent 반복 {}: finish_reason={}", i + 1, finishReason);

            if ("stop".equals(finishReason)) break;

            if (!"tool_calls".equals(finishReason)) {
                log.warn("예상치 못한 finish_reason: {}", finishReason);
                break;
            }

            List<GptToolCall> toolCalls = response.getToolCalls();
            if (toolCalls == null || toolCalls.isEmpty()) break;

            messages.add(GptChatRequest.Message.ofAssistantToolCalls(toolCalls));

            for (GptToolCall call : toolCalls) {
                String toolName = call.getFunction().getName();
                String argsJson = call.getFunction().getArguments();

                try {
                    JsonNode args = objectMapper.readTree(argsJson);

                    if (TOOL_SEARCH_HOSPITALS.equals(toolName)) {
                        departmentCode = args.path("dgsbjtCd").asText();
                        departmentName = args.path("departmentName").asText();

                        // clCd 범위·반경은 위험도 기반 서버 로직으로 결정
                        hospitals = searchAcrossHospitalTypes(departmentCode, req);

                        String result = objectMapper.writeValueAsString(
                                Map.of("success", true, "totalCount", hospitals.getTotalCount()));
                        messages.add(GptChatRequest.Message.ofToolResult(call.getId(), result));
                        log.debug("search_hospitals: dgsbjtCd={}, totalCount={}", departmentCode, hospitals.getTotalCount());

                    } else if (TOOL_EXTRACT_ICD10.equals(toolName)) {
                        icd10Code = args.path("icd10Code").asText();

                        messages.add(GptChatRequest.Message.ofToolResult(
                                call.getId(), "{\"recorded\":true}"));
                        log.debug("extract_icd10_code: code={}", icd10Code);
                    }

                } catch (Exception e) {
                    log.error("Tool 실행 실패: tool={}, error={}", toolName, e.getMessage());
                    messages.add(GptChatRequest.Message.ofToolResult(
                            call.getId(), "{\"error\":\"" + e.getMessage() + "\"}"));
                }
            }

            if (hospitals != null && icd10Code != null) {
                log.debug("Agent: 두 Tool 완료 → Loop 종료");
                break;
            }
        }

        if (hospitals == null) {
            throw new ExternalApiException("AGENT_INCOMPLETE", "병원 검색을 완료하지 못했습니다. 다시 시도해 주세요.");
        }

        return HospitalAssistantResponse.builder()
                .departmentCode(departmentCode)
                .departmentName(departmentName)
                .hospitals(hospitals)
                .icd10Code(icd10Code)
                .build();
    }

    // ── 다중 병원 종별 HIRA 호출 + 병합 ───────────────────────────────

    /**
     * 위험도에 해당하는 clCd 목록 각각에 대해 HIRA API를 순차 호출하고
     * ykiho 기준으로 중복을 제거한 뒤 병합합니다.
     */
    private HospitalSearchResponse searchAcrossHospitalTypes(
            String dgsbjtCd, HospitalAssistantRequest req) {

        List<String> clCds = RISK_TO_CL_CDS.getOrDefault(req.getRiskLevel(), List.of("31", "21", "11", "01"));
        int radius         = RISK_TO_RADIUS.getOrDefault(req.getRiskLevel(), 3000);

        // LinkedHashMap으로 삽입 순서(종별 우선순위) 유지하면서 ykiho 중복 제거
        Map<String, HospitalDto> merged = new LinkedHashMap<>();
        int totalCount = 0;

        for (String clCd : clCds) {
            try {
                HospitalSearchRequest searchReq = buildSearchRequest(dgsbjtCd, clCd, radius, req);
                HospitalSearchResponse result   = hiraApiService.searchHospitals(searchReq);

                totalCount += result.getTotalCount();
                for (HospitalDto hospital : result.getHospitals()) {
                    if (hospital.getYkiho() != null) {
                        merged.putIfAbsent(hospital.getYkiho(), hospital);
                    }
                }
                log.debug("HIRA 조회: clCd={}, 건수={}", clCd, result.getTotalCount());

            } catch (Exception e) {
                log.warn("clCd={} 병원 검색 실패 (건너뜀): {}", clCd, e.getMessage());
            }
        }

        // 단일 IN 쿼리로 인증 병원 ykiho Set 확보 (N+1 방지)
        Set<String> certifiedYkihos = foreignCertifiedHospitalRepository
                .findAllByYkihoIn(merged.keySet()) // DB 조히
                .stream()
                .map(ForeignCertifiedHospital::getYkiho)
                .collect(Collectors.toSet());

        List<HospitalDto> hospitals = merged.values().stream()
                .map(dto -> HospitalDto.builder()
                        .ykiho(dto.getYkiho())
                        .hospitalName(dto.getHospitalName())
                        .address(dto.getAddress())
                        .telephone(dto.getTelephone())
                        .longitude(dto.getLongitude())
                        .latitude(dto.getLatitude())
                        .distance(dto.getDistance())
                        .hospitalType(dto.getHospitalType())
                        .foreignCertified(certifiedYkihos.contains(dto.getYkiho()))  // 병원별 판별
                        .build())
                .collect(Collectors.toList());
        return HospitalSearchResponse.builder()
                .hospitals(hospitals)
                .pageNo(1)
                .numOfRows(hospitals.size())
                .totalCount(totalCount)
                .build();
    }

    // ── 초기 메시지 ──────────────────────────────────────────────────

    private List<GptChatRequest.Message> buildInitialMessages(
            HospitalAssistantRequest req, UserProfileDto profile) {

        String patientContext = profile.isGuest()
                ? "Patient context: Guest user | Risk level: %d/5 (no profile — ICD-10 only cost estimation)".formatted(req.getRiskLevel())
                : "Patient context: Age: %d | Gender: %s | Insured: %s | Risk level: %d/5".formatted(
                        profile.getAge(), profile.getGender(),
                        profile.isInsured() ? "yes" : "no", req.getRiskLevel());

        String systemPrompt = """
                You are a medical AI agent for a hospital-finding application in Korea.
                You MUST call BOTH tools before finishing:
                  1. search_hospitals — analyze symptoms and choose the best HIRA department code
                  2. extract_icd10_code — extract the ICD-10 code for cost estimation

                %s

                Available HIRA department codes:
                  00:일반의, 01:내과, 02:신경과, 03:정신건강의학과, 04:피부과,
                  05:외과, 06:흉부외과, 07:정형외과, 08:신경외과, 09:산부인과,
                  10:소아청소년과, 11:안과, 12:이비인후과, 13:비뇨의학과,
                  18:재활의학과, 20:가정의학과, 21:응급의학과, 24:치과
                """.formatted(patientContext);

        List<GptChatRequest.Message> messages = new ArrayList<>();
        messages.add(new GptChatRequest.Message("system", systemPrompt));
        messages.add(new GptChatRequest.Message("user", req.getSymptom()));
        return messages;
    }

    // ── Tool 정의 ─────────────────────────────────────────────────────

    private List<GptTool> buildTools() {
        GptTool searchHospitals = new GptTool(
                GptTool.Function.builder()
                        .name(TOOL_SEARCH_HOSPITALS)
                        .description("증상을 분석하여 적합한 HIRA 진료과목 코드를 결정합니다. 병원 종별·반경은 서버에서 위험도 기반으로 자동 처리됩니다.")
                        .parameters(Map.of(
                                "type", "object",
                                "properties", Map.of(
                                        "dgsbjtCd", Map.of(
                                                "type", "string",
                                                "description", "HIRA 진료과목 코드 (예: '01'=내과, '12'=이비인후과)"
                                        ),
                                        "departmentName", Map.of(
                                                "type", "string",
                                                "description", "진료과 이름 (한국어)"
                                        )
                                ),
                                "required", List.of("dgsbjtCd", "departmentName")
                        ))
                        .build()
        );

        GptTool extractIcd10 = new GptTool(
                GptTool.Function.builder()
                        .name(TOOL_EXTRACT_ICD10)
                        .description("증상을 분석하여 ICD-10 코드를 추출합니다. 의료비 예측에 사용됩니다.")
                        .parameters(Map.of(
                                "type", "object",
                                "properties", Map.of(
                                        "icd10Code", Map.of(
                                                "type", "string",
                                                "description", "ICD-10 코드 (예: 'J06.9', 'M54.5')"
                                        )
                                ),
                                "required", List.of("icd10Code")
                        ))
                        .build()
        );

        return List.of(searchHospitals, extractIcd10);
    }

    // ── HIRA 검색 요청 생성 ───────────────────────────────────────────

    private HospitalSearchRequest buildSearchRequest(
            String dgsbjtCd, String clCd, int radius, HospitalAssistantRequest req) {

        HospitalSearchRequest r = new HospitalSearchRequest();
        r.setDgsbjtCd(dgsbjtCd);
        r.setClCd(clCd);
        r.setXPos(req.getLongitude());
        r.setYPos(req.getLatitude());
        r.setRadius(radius);
        return r;
    }
}
