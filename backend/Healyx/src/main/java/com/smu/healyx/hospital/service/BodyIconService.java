package com.smu.healyx.hospital.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.hospital.dto.BodyIconResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.Map;

/**
 * 신체 아이콘 ID를 증상 키워드로 매핑하는 정적 서비스 (HX_H_002, UI-HOS-05).
 *
 * <p>DB·LLM 호출 없이 서버 내 불변 Map으로 처리하여 레이턴시 0에 가깝다.
 *
 * <p>키 표기는 Flutter assets 파일명 기반(예: {@code HEADACHE}, {@code BROKEN-BONE})이며,
 * 입력 iconId는 대문자 정규화하여 케이스 차이를 흡수한다.
 *
 * <p>본 서비스는 {@code HospitalRecommendService.mapBodyIconToKeyword()}에서
 * 위임 호출되며 외부 컨트롤러는 통합 서비스 메소드를 통해 진입한다.
 */
@Slf4j
@Service
public class BodyIconService {

    /**
     * 신체 부위·증상 → 증상 키워드 매핑.
     * 키 표기는 Flutter assets 아이콘 파일명 prefix(소문자 하이픈) 기반이며,
     * {@link #getKeywords(String)} 내부에서 대문자 정규화하여 비교한다.
     *
     * <p><b>주의 — Flutter 합의 미완 항목</b>
     * <ul>
     *   <li>{@code DROPLET}: 아이콘 의도(혈액·체액·발열) 명확치 않아 보편적 해석으로 매핑.
     *       Flutter 팀 합의 후 키워드 재조정 필요.</li>
     *   <li>iconId 호출 통합: 현재 Flutter 측 onTap이 본 API를 호출하지 않고
     *       다음 화면으로 직접 넘기는 상태. 통합 시점에 매핑 키 명명 재확인.</li>
     * </ul>
     */
    private static final Map<String, String> KEYWORD_MAP = Map.ofEntries(
            Map.entry("HEADACHE",        "두통, 어지러움, 메스꺼움"),
            Map.entry("STOMACHACHE",     "복통, 소화불량, 구역질"),
            Map.entry("TOOTHACHE",       "치통, 잇몸통증, 이 시림"),
            Map.entry("DROPLET",         "발열, 식은땀, 오한"),       // ⚠️ Flutter 의도 확인 필요
            Map.entry("BROKEN-BONE",     "골절, 외상, 타박상"),
            Map.entry("EAR",             "귀통증, 이명, 청력저하"),
            Map.entry("SKIN",            "발진, 가려움, 두드러기"),
            Map.entry("HEAD-SIDE-COUGH", "기침, 가래, 호흡곤란"),
            Map.entry("VISIBLE",         "시력저하, 눈충혈, 눈통증"),
            Map.entry("NOSE",            "코막힘, 콧물, 코피"),
            Map.entry("COLD",            "감기, 발열, 오한"),
            Map.entry("DISK",            "허리통증, 디스크 통증, 다리 저림")
    );

    /**
     * iconId에 매핑된 증상 키워드를 반환.
     * iconId 표기 차이(head, Head, HEAD)는 모두 동일하게 처리.
     *
     * @throws AuthException 매핑이 없는 경우 404
     */
    public BodyIconResponse getKeywords(String iconId) {
        if (!StringUtils.hasText(iconId)) {
            throw new AuthException(
                    "INVALID_PARAM",
                    "아이콘 ID를 입력해 주세요.",
                    HttpStatus.BAD_REQUEST);
        }

        String key = iconId.trim().toUpperCase();
        String keywords = KEYWORD_MAP.get(key);

        if (keywords == null) {
            log.warn("매핑되지 않은 신체 아이콘 요청: iconId={}", iconId);
            throw new AuthException(
                    "ICON_NOT_FOUND",
                    "지원하지 않는 신체 부위 아이콘입니다.",
                    HttpStatus.NOT_FOUND);
        }

        return new BodyIconResponse(key, keywords);
    }
}
