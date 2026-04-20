package com.smu.healyx.gpt.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.gpt.dto.SymptomAnalysisRequest;
import com.smu.healyx.gpt.dto.SymptomAnalysisResponse;
import com.smu.healyx.gpt.service.GptService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** GPT 증상 분석 엔드포인트 */
@RestController
@RequestMapping("/api/gpt")
@RequiredArgsConstructor
public class GptController {

    private final GptService gptService;

    /**
     * 증상 텍스트를 분석하여 HIRA 진료과목 코드를 반환합니다.
     * 게스트 허용 — 8개 언어 모두 지원
     *
     * POST /api/gpt/analyze-symptom
     */
    @PostMapping("/analyze-symptom")
    public ResponseEntity<ApiResponse<SymptomAnalysisResponse>> analyzeSymptom(
            @Valid @RequestBody SymptomAnalysisRequest request) {

        String[] result = gptService.extractDepartmentCode(request.getSymptom());

        SymptomAnalysisResponse response = SymptomAnalysisResponse.builder()
                .dgsbjtCd(result[0])
                .departmentName(result[1])
                .build();

        return ResponseEntity.ok(ApiResponse.success(response));
    }
}