package com.smu.healyx.hospital.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.util.List;

/**
 * 병원 추천 + 카드별 의료비 예측 통합 응답 DTO.
 *
 * <p>PM 합의(2026-05-08): 화면설계서 UI-HOS-07 정합을 위해
 * {@code POST /api/hospitals/recommend} 단일 호출에서 추천과 의료비 예측 결과를
 * 동시에 반환한다. 의료비 예측 단독 엔드포인트({@code /api/cost/predict})는 폐지.
 *
 * <p>의료비 예측은 로그인 사용자에게만 수행되며, 게스트 사용자는 카드의 cost
 * 관련 필드가 null로 직렬화된다.
 */
@Getter
@Builder
@AllArgsConstructor
public class HospitalRecommendResponse {

    /** GPT Agent가 분석한 HIRA 진료과목 코드 (예: "01") */
    private String departmentCode;

    /** 진료과 이름 (예: "내과") */
    private String departmentName;

    /** GPT Agent가 추출한 ICD-10 코드 — 카드별 의료비 예측에 활용 */
    private String icd10Code;

    /**
     * 추천 병원 카드 목록 (최대 5개).
     * 각 카드는 병원 정보 + 의료비 예측 결과(minCost·maxCost·visitType) 포함.
     */
    private List<HospitalCardDto> hospitals;

    /** 조회된 총 병원 수 */
    private int totalCount;

    /** 반경 내 병원 존재 여부 */
    private boolean hasResult;

    /** 결과 없음 사유 — hasResult=false일 때만 값 존재 */
    private String emptyReason;
}
