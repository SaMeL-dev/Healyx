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

    /** 경도 — 지도 렌더링은 Flutter가 전담, 서버는 좌표만 전달 */
    private String longitude;

    /** 위도 */
    private String latitude;

    /** 종별코드명 (예: 의원, 병원, 종합병원) */
    private String hospitalType;

    /**
     * 외국인 환자 유치 인증 병원 여부
     * - foreign_certified_hospital 테이블에서 ykiho 기준으로 조회
     * - DB 연동 완료 전까지 false 반환
     */
    private boolean foreignCertified;
}