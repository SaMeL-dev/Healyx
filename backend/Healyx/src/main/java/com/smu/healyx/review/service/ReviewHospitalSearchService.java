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
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReviewHospitalSearchService {

    private final HiraApiService hiraApiService;
    private final HospitalRepository hospitalRepository;
    private final ReviewRepository reviewRepository;

    private static final int MAX_NUM_OF_ROWS = 100;
    private static final int MIN_NAME_LENGTH = 1;
    private static final int MAX_HIRA_PAGES = 5;

    @Transactional
    public ReviewHospitalSearchResponse search(String name, String region, int page, int size) {

        validate(name, page, size);

        List<HospitalDto> pageHospitals;
        int totalCount;

        if (StringUtils.hasText(region)) {
            pageHospitals = fetchAllFromHiraParallel(name.trim()).stream()
                    .filter(h -> h.getAddress() != null && h.getAddress().startsWith(region.trim()))
                    .toList();
            totalCount = pageHospitals.size();
        } else {
            HospitalSearchRequest request = new HospitalSearchRequest();
            request.setYadmNm(name.trim());
            request.setPageNo(page + 1);
            request.setNumOfRows(size);
            HospitalSearchResponse resp = hiraApiService.searchHospitals(request);
            pageHospitals = resp.getHospitals();
            totalCount = resp.getTotalCount();
        }

        List<ReviewHospitalItem> items = upsertAndBuildItems(pageHospitals);

        log.debug("리뷰 병원 검색 완료: name={}, region={}, total={}, returned={}",
                name, region, totalCount, items.size());

        return ReviewHospitalSearchResponse.builder()
                .totalCount(totalCount)
                .hospitals(items)
                .build();
    }

    // ── 내부 ─────────────────────────────────────────────────────────

    /**
     * upsert + 별점/리뷰 수 집계를 배치 쿼리로 처리.
     * 기존 toItem(N+1) + upsertHospitals(N+1) → 쿼리 3회로 대체.
     */
    private List<ReviewHospitalItem> upsertAndBuildItems(List<HospitalDto> dtos) {
        if (dtos.isEmpty()) return List.of();

        List<String> ykihos = dtos.stream()
                .map(HospitalDto::getYkiho)
                .filter(y -> y != null && !y.isBlank())
                .toList();

        // 1 query: 기존 병원 일괄 조회
        Map<String, Hospital> hospitalMap = new HashMap<>(
                hospitalRepository.findAllByYkihoIn(ykihos).stream()
                        .collect(Collectors.toMap(Hospital::getYkiho, h -> h))
        );

        // upsert: 신규는 saveAll, 기존은 updateFromHira
        List<Hospital> toSave = new ArrayList<>();
        for (HospitalDto dto : dtos) {
            if (dto.getYkiho() == null || dto.getYkiho().isBlank()) continue;
            Hospital existing = hospitalMap.get(dto.getYkiho());
            if (existing != null) {
                existing.updateFromHira(dto);
            } else {
                toSave.add(Hospital.fromHiraDto(dto));
            }
        }
        if (!toSave.isEmpty()) {
            hospitalRepository.saveAll(toSave)
                    .forEach(h -> hospitalMap.put(h.getYkiho(), h));
        }

        // 1 query: 별점·리뷰 수 일괄 집계
        List<Long> hospitalIds = hospitalMap.values().stream()
                .map(Hospital::getHospitalId)
                .filter(Objects::nonNull)
                .toList();

        Map<Long, double[]> statsMap = new HashMap<>();
        if (!hospitalIds.isEmpty()) {
            reviewRepository.findRatingStatsByHospitalIds(hospitalIds).forEach(row -> {
                Long hid = (Long) row[0];
                Double avg = (Double) row[1];
                Long cnt = (Long) row[2];
                statsMap.put(hid, new double[]{avg == null ? 0.0 : avg, cnt == null ? 0 : cnt});
            });
        }

        return dtos.stream().map(dto -> {
            Hospital hospital = hospitalMap.get(dto.getYkiho());
            double averageRating = 0.0;
            int reviewCount = 0;
            if (hospital != null) {
                double[] stats = statsMap.get(hospital.getHospitalId());
                if (stats != null) {
                    averageRating = BigDecimal.valueOf(stats[0])
                            .setScale(1, RoundingMode.HALF_UP).doubleValue();
                    reviewCount = (int) stats[1];
                }
            }
            return ReviewHospitalItem.builder()
                    .ykiho(dto.getYkiho())
                    .name(dto.getHospitalName())
                    .address(dto.getAddress())
                    .averageRating(averageRating)
                    .reviewCount(reviewCount)
                    .build();
        }).toList();
    }

    /**
     * 첫 페이지로 totalCount를 확인한 뒤 나머지 페이지를 CompletableFuture로 병렬 호출.
     * RestTemplate은 스레드 안전하므로 병렬 호출 가능.
     */
    private List<HospitalDto> fetchAllFromHiraParallel(String name) {
        HospitalSearchRequest firstReq = new HospitalSearchRequest();
        firstReq.setYadmNm(name);
        firstReq.setPageNo(1);
        firstReq.setNumOfRows(MAX_NUM_OF_ROWS);
        HospitalSearchResponse firstResp = hiraApiService.searchHospitals(firstReq);

        List<HospitalDto> all = new ArrayList<>(firstResp.getHospitals());
        if (all.size() >= firstResp.getTotalCount()) return all;

        int totalPages = Math.min(
                (int) Math.ceil((double) firstResp.getTotalCount() / MAX_NUM_OF_ROWS),
                MAX_HIRA_PAGES
        );
        if (totalPages <= 1) return all;

        List<CompletableFuture<List<HospitalDto>>> futures = new ArrayList<>();
        for (int p = 2; p <= totalPages; p++) {
            final int pageNum = p;
            futures.add(CompletableFuture.supplyAsync(() -> {
                HospitalSearchRequest req = new HospitalSearchRequest();
                req.setYadmNm(name);
                req.setPageNo(pageNum);
                req.setNumOfRows(MAX_NUM_OF_ROWS);
                return hiraApiService.searchHospitals(req).getHospitals();
            }));
        }

        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();
        for (CompletableFuture<List<HospitalDto>> future : futures) {
            try {
                List<HospitalDto> batch = future.get();
                if (batch != null) all.addAll(batch);
            } catch (Exception e) {
                log.warn("HIRA 병렬 페이지 조회 실패: {}", e.getMessage());
            }
        }

        return all;
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
