package com.smu.healyx.hira.controller;

import com.smu.healyx.common.dto.ApiResponse;
import com.smu.healyx.hira.dto.HospitalSearchRequest;
import com.smu.healyx.hira.dto.HospitalSearchResponse;
import com.smu.healyx.hira.service.HiraApiService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/hospitals")
@RequiredArgsConstructor
public class HospitalController {

    private final HiraApiService hiraApiService;

    /**
     * 병원 검색 (게스트 허용)
     *
     * 현재: 클라이언트가 dgsbjtCd를 직접 전달
     * 추후: GPT 증상 분석 → dgsbjtCd 자동 추출 → 의료비 예측 통합 엔드포인트로 확장
     *
     * POST /api/hospitals/search
     */
    @PostMapping("/search")
    public ResponseEntity<ApiResponse<HospitalSearchResponse>> searchHospitals(
            @Valid @RequestBody HospitalSearchRequest request) {

        HospitalSearchResponse response = hiraApiService.searchHospitals(request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }
}