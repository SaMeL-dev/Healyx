package com.smu.healyx.hira.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class HospitalSearchRequest {
    
    /**
     * 진료과목코드 (필수)
     GPT 증상 분석으로 진료과를 추출하고 추출한 진료과로 병원 탐색
     */
    private String dgsbjtCd;

    /** 종별코드 (필수) — 01:상급종합, 11:종합병원, 21:병원, 31:의원
     *  위험도에 따른 요청 종별 코드 값이 있어야 함
     * */
    private String clCd;

    /** 경도 — 클라이언트 현재 위치 (Flutter GPS) */
    private String xPos;

    /** 위도 — 클라이언트 현재 위치 (Flutter GPS) */
    private String yPos;

    /** 검색 반경 (단위: km, 위험도에 따른 반경 나누어 기입) */
    private String radius;

    /** 페이지 번호 (기본 1) */
    private int pageNo = 1;

    /** 한 페이지 결과 수 (기본 20, 최대 100) */
    private int numOfRows = 20;
}