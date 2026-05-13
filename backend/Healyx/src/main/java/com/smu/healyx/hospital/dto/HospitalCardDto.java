package com.smu.healyx.hospital.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.smu.healyx.hira.dto.HospitalDto;
import lombok.Builder;
import lombok.Getter;

/**
 * 병원 추천 결과 카드 DTO.
 *
 * <p>화면설계서 UI-HOS-07 / 요구사항 HOS-010 정합:
 * 병원 카드 = 병원명 + 주소 + 예측 진료비(최소~최대) + 별점 + 외국인 인증 배지.
 *
 * <p>구조: {@link HospitalDto} 필드 전체 + 카드별 의료비 예측 결과 평면 필드.
 * 게스트 사용자의 경우 의료비 예측을 수행하지 않으므로
 * {@code minCost}, {@code maxCost}, {@code visitType}이 null로 직렬화 제외된다
 * (Flutter는 minCost == null 여부로 보험 미적용 안내 아이콘 분기 가능).
 */
@Getter
@Builder
public class HospitalCardDto {

    // ── HospitalDto 동일 필드 ─────────────────────────────────────────
    private String ykiho;
    private String hospitalName;
    private String address;
    private String telephone;
    private double longitude;
    private double latitude;
    private int    distance;
    private String clCd;
    private String hospitalType;
    private String sidoCd;
    private String sidoCdNm;
    private boolean foreignCertified;

    // ── 의료비 예측 평면 필드 (게스트는 null → JSON 키 자체 제외) ─────
    /** 최저 예상 비용(원). 게스트 또는 예측 실패 시 null. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private Integer minCost;

    /** 최고 예상 비용(원). 게스트 또는 예측 실패 시 null. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private Integer maxCost;

    /** 방문 유형(outpatient/inpatient). 게스트 또는 예측 실패 시 null. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private String visitType;

    /**
     * 의료비 예측 미수행 사유. 정상 예측 시 null.
     * 예: "GUEST_NOT_LOGGED_IN", "COST_REFERENCE_NOT_FOUND".
     * Flutter 안내 아이콘 분기 보조용. 정상 카드에는 노출 안 됨.
     */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    private String costUnavailableReason;

    /**
     * HospitalDto + 의료비 예측 결과 → HospitalCardDto 조립.
     *
     * @param hospital   HIRA 응답 병원 정보
     * @param minCost    최저 예상 비용 (게스트/실패 시 null)
     * @param maxCost    최고 예상 비용 (게스트/실패 시 null)
     * @param visitType  방문 유형 (게스트/실패 시 null)
     * @param reason     예측 미수행 사유 (정상 예측 시 null)
     */
    public static HospitalCardDto of(HospitalDto hospital,
                                     Integer minCost,
                                     Integer maxCost,
                                     String  visitType,
                                     String  reason) {
        return HospitalCardDto.builder()
                .ykiho(hospital.getYkiho())
                .hospitalName(hospital.getHospitalName())
                .address(hospital.getAddress())
                .telephone(hospital.getTelephone())
                .longitude(hospital.getLongitude())
                .latitude(hospital.getLatitude())
                .distance(hospital.getDistance())
                .clCd(hospital.getClCd())
                .hospitalType(hospital.getHospitalType())
                .sidoCd(hospital.getSidoCd())
                .sidoCdNm(hospital.getSidoCdNm())
                .foreignCertified(hospital.isForeignCertified())
                .minCost(minCost)
                .maxCost(maxCost)
                .visitType(visitType)
                .costUnavailableReason(reason)
                .build();
    }
}
