package com.smu.healyx.hira.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class HospitalDto {

    /** 병원 식별 핵심 키 (암호화된 요양기호) */
    private String ykiho;

    /** 병원명 */
    private String hospitalName;

    /** 주소 */
    private String address;

    /** 전화번호 */
    private String telephone;

    /** 경도 — 지도 렌더링은 Flutter가 전담, 서버는 좌표만 전달. 소수점 15자리 정밀도 */
    private double longitude;

    /** 위도 — 소수점 15자리 정밀도 */
    private double latitude;

    /** 검색 위치 기준 거리 (m) — 위치 기반 검색 시에만 유효, 병원 추천 스코어링에 사용 */
    private int distance;

    /**
     * 종별코드 (예: "01", "11", "21", "31").
     * 의료비 예측의 hospital_type_adjustment 매칭 키.
     */
    private String clCd;

    /** 종별코드명 (예: "상급종합병원", "종합병원", "병원", "의원") — 카드 표시용 */
    private String hospitalType;

    /**
     * 시도코드 (HIRA sidoCd, 예: "110000").
     * 카드 응답 메타로 보존 (Flutter 화면 분기에 활용 가능).
     */
    private String sidoCd;

    /**
     * 시도코드명 (HIRA sidoCdNm, 예: "서울", "부산", "경기").
     * 의료비 예측의 region_adjustment 매칭 키.
     */
    private String sidoCdNm;

    /**
     * 외국인 환자 유치 인증 병원 여부
     * - foreign_certified_hospital 테이블에서 ykiho 기준으로 조회
     */
    private boolean foreignCertified;
}
