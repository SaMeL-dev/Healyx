package com.smu.healyx.hira.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * HIRA Open API (getHospBasisList) 병원 단건 응답 항목
 */
@Getter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class HiraItem {

    /** 암호화된 요양기호 — 병원 식별 핵심 키 */
    private String ykiho;

    /** 병원명 */
    private String yadmNm;

    /** 주소 */
    private String addr;

    /** 전화번호 */
    private String telno;

    /** 경도 (XPos) — 소수점 15자리 정밀도 */
    @JsonProperty("XPos")
    private double longitude;

    /** 위도 (YPos) — 소수점 15자리 정밀도 */
    @JsonProperty("YPos")
    private double latitude;

    /** 검색 위치 기준 거리 — HIRA API가 소수점 문자열로 반환하므로 double로 파싱 */
    @JsonProperty("distance")
    private double distance;

    /** 종별코드 (예: "01"=상급종합, "31"=의원) */
    private String clCd;

    /** 종별코드명 (예: "상급종합병원", "의원") */
    private String clCdNm;

    /**
     * 시도코드 (예: "110000"=서울, "210000"=부산).
     * 의료비 예측의 지역 보정계수 산출에 활용.
     */
    private String sidoCd;

    /**
     * 시도코드명 (예: "서울", "부산", "경기").
     * region_adjustment 테이블의 region 컬럼과 매칭.
     */
    private String sidoCdNm;
}
