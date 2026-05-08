package com.smu.healyx.review.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.hira.dto.HospitalDto;
import com.smu.healyx.hira.dto.HospitalSearchRequest;
import com.smu.healyx.hira.dto.HospitalSearchResponse;
import com.smu.healyx.hira.service.HiraApiService;
import com.smu.healyx.hospital.domain.Hospital;
import com.smu.healyx.hospital.repository.HospitalRepository;
import com.smu.healyx.review.dto.ReviewHospitalItem;
import com.smu.healyx.review.dto.ReviewHospitalSearchResponse;
import com.smu.healyx.review.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

/**
 * 리뷰 작성 전 진입 화면(UI-REV-01, UI-REV-02)에서 병원을 직접 검색한다.
 *
 * <p>병원 추천(HOS) 플로우와 달리 GPT 진료과 분석을 거치지 않고
 * HIRA Open API의 병원명 검색(yadmNm)으로 단순 호출하며,
 * 결과는 OCR 인증 선행 조건(ykiho ↔ 병원명 대조)을 만족시키기 위해
 * hospitals 테이블에 upsert한다.
 *
 * <p>책임 범위가 좁아 ReviewService(OCR/CRUD/S3)와 분리하여 응집도를 유지한다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ReviewHospitalSearchService {

    private final HiraApiService hiraApiService;
    private final HospitalRepository hospitalRepository;
    private final ReviewRepository reviewRepository;

    private static final int MAX_NUM_OF_ROWS = 100;
    private static final int MIN_NAME_LENGTH = 1;

    /**
     * 병원명 + (선택)지역으로 HIRA 검색 후 평균 별점·리뷰 수 포함 카드 리스트 반환.
     *
     * @param name   병원명 키워드 (필수, 공백 비허용)
     * @param region 시도 단위 지역 prefix (선택, 예: "서울", "부산")
     * @param page   0-base 페이지 (HIRA pageNo는 1-base이므로 +1 변환)
     * @param size   페이지 크기 (1~100)
     */
    @Transactional
    public ReviewHospitalSearchResponse search(String name, String region, int page, int size) {

        validate(name, page, size);

        // 1. HIRA API 호출 (yadmNm 기준)
        HospitalSearchRequest request = new HospitalSearchRequest();
        request.setYadmNm(name.trim());
        request.setPageNo(page + 1); // HIRA는 1-base
        request.setNumOfRows(size);
        HospitalSearchResponse hiraResponse = hiraApiService.searchHospitals(request);

        // 2. region 후처리 필터 (addr startsWith)
        List<HospitalDto> hospitals = hiraResponse.getHospitals();
        if (StringUtils.hasText(region)) {
            String prefix = region.trim();
            hospitals = hospitals.stream()
                    .filter(h -> h.getAddress() != null && h.getAddress().startsWith(prefix))
                    .toList();
        }

        // 3. hospitals 테이블 upsert — OCR 인증·리뷰 등록 선행 조건
        upsertHospitals(hospitals);

        // 4. 별점·리뷰 수 집계하여 카드 변환
        List<ReviewHospitalItem> items = hospitals.stream()
                .map(this::toItem)
                .toList();

        log.debug("리뷰 병원 검색 완료: name={}, region={}, count={}", name, region, items.size());

        return ReviewHospitalSearchResponse.builder()
                .totalCount(items.size())
                .hospitals(items)
                .build();
    }

    // ── 내부 ─────────────────────────────────────────────────────────

    /**
     * HIRA DTO를 응답 카드로 변환하면서 평균 별점·리뷰 수를 집계한다.
     * upsert 직후라 hospital 행은 항상 존재해야 정상이지만, 방어적으로 0.0/0 처리.
     */
    private ReviewHospitalItem toItem(HospitalDto dto) {
        Hospital hospital = hospitalRepository.findByYkiho(dto.getYkiho()).orElse(null);

        double averageRating = 0.0;
        int reviewCount = 0;
        if (hospital != null) {
            Double avgRaw = reviewRepository.findAvgRatingByHospitalId(hospital.getHospitalId());
            averageRating = avgRaw == null ? 0.0
                    : BigDecimal.valueOf(avgRaw).setScale(1, RoundingMode.HALF_UP).doubleValue();
            reviewCount = reviewRepository.countByHospitalId(hospital.getHospitalId());
        }

        return ReviewHospitalItem.builder()
                .ykiho(dto.getYkiho())
                .name(dto.getHospitalName())
                .address(dto.getAddress())
                .averageRating(averageRating)
                .reviewCount(reviewCount)
                .build();
    }

    /**
     * HIRA 응답 병원 목록을 ykiho 기준으로 hospitals 테이블에 upsert.
     * HospitalRecommendService.upsertHospitals와 동일 패턴.
     */
    private void upsertHospitals(List<HospitalDto> dtos) {
        for (HospitalDto dto : dtos) {
            if (dto.getYkiho() == null || dto.getYkiho().isBlank()) continue;

            hospitalRepository.findByYkiho(dto.getYkiho())
                    .ifPresentOrElse(
                            existing -> existing.updateFromHira(dto),
                            () -> hospitalRepository.save(Hospital.fromHiraDto(dto))
                    );
        }
    }

    private void validate(String name, int page, int size) {
        if (!StringUtils.hasText(name) || name.trim().length() < MIN_NAME_LENGTH) {
            throw new AuthException(
                    "INVALID_PARAM",
                    "병원명을 입력해 주세요.",
                    HttpStatus.BAD_REQUEST);
        }
        if (page < 0) {
            throw new AuthException(
                    "INVALID_PARAM",
                    "페이지 번호는 0 이상이어야 합니다.",
                    HttpStatus.BAD_REQUEST);
        }
        if (size < 1 || size > MAX_NUM_OF_ROWS) {
            throw new AuthException(
                    "INVALID_PARAM",
                    "페이지 크기는 1~100 사이여야 합니다.",
                    HttpStatus.BAD_REQUEST);
        }
    }
}
