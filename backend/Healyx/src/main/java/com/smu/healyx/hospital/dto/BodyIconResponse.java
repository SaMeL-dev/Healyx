package com.smu.healyx.hospital.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 신체 아이콘 → 증상 키워드 매핑 응답 (HOS-002, UI-HOS-05).
 * Flutter가 다중 선택 시 본 응답을 N회 호출하여 키워드를 합성한 후
 * /api/hospitals/recommend의 symptom 입력으로 활용한다.
 */
@Getter
@AllArgsConstructor
public class BodyIconResponse {

    /** 정규화된 아이콘 ID (대문자) */
    private final String iconId;

    /** 콤마+공백 구분 증상 키워드 (예: "두통, 어지러움, 메스꺼움") */
    private final String keywords;
}
