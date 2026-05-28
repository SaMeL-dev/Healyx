package com.smu.healyx.hospital.service;

import com.smu.healyx.agent.service.HospitalAgentService;
import com.smu.healyx.hira.dto.HospitalDto;
import com.smu.healyx.review.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 병원 추천 스코어링 서비스.
 *
 * <p>가중치 기반 스코어링 (CLAUDE.md §11.1 구두합의):
 * <ul>
 *   <li>Normal (리뷰 >= 10건): 0.35 * typeScore + 0.30 * foreignScore + 0.15 * reviewScore + 0.20 * distanceScore</li>
 *   <li>Cold Start (리뷰 < 10건): 0.50 * typeScore + 0.30 * foreignScore + 0.20 * distanceScore</li>
 * </ul>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class HospitalScoringService {

    private final ReviewRepository reviewRepository;

    /**
     * 스코어링 결과를 담는 내부 레코드.
     *
     * @param score       가중 합산 점수 (0.0~1.0)
     * @param avgRating   평균 별점 (리뷰 없으면 null)
     * @param reviewCount 리뷰 건수
     */
    public record ScoredHospital(double score, Double avgRating, int reviewCount) {}

    /**
     * 병원 목록에 대해 스코어링을 수행한다.
     *
     * @param hospitals         HIRA 응답 병원 목록
     * @param ykihoToHospitalId ykiho → hospitalId 매핑 (upsert 결과)
     * @param riskLevel         위험도 (1~5)
     * @return ykiho → ScoredHospital 매핑
     */
    public Map<String, ScoredHospital> score(List<HospitalDto> hospitals,
                                             Map<String, Long> ykihoToHospitalId,
                                             int riskLevel) {

        // ── 1. 리뷰 통계 배치 조회 ─────────────────────────────────────
        List<Long> hospitalIds = ykihoToHospitalId.values().stream()
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());

        // hospitalId → [avgRating, reviewCount]
        Map<Long, double[]> ratingStatsMap = new HashMap<>();
        if (!hospitalIds.isEmpty()) {
            List<Object[]> stats = reviewRepository.findRatingStatsByHospitalIds(hospitalIds);
            for (Object[] row : stats) {
                Long id        = (Long) row[0];
                Double avg     = (Double) row[1];
                Long count     = (Long) row[2];
                ratingStatsMap.put(id, new double[]{
                        avg != null ? avg : 0.0,
                        count != null ? count : 0
                });
            }
        }

        // ── 2. 스코어링 상수 ───────────────────────────────────────────
        List<String> clCds = HospitalAgentService.RISK_TO_CL_CDS
                .getOrDefault(riskLevel, List.of("31", "21", "11", "01"));
        int radius = HospitalAgentService.RISK_TO_RADIUS
                .getOrDefault(riskLevel, 3000);

        // ── 3. 병원별 스코어 계산 ──────────────────────────────────────
        Map<String, ScoredHospital> result = new LinkedHashMap<>();

        for (HospitalDto h : hospitals) {
            String ykiho = h.getYkiho();

            // typeScore: 선호 종별 리스트에서의 선형 비례
            double typeScore = computeTypeScore(h.getClCd(), clCds);

            // foreignScore: 인증 여부
            double foreignScore = h.isForeignCertified() ? 1.0 : 0.0;

            // reviewScore + reviewCount 조회
            Long hospitalId = ykihoToHospitalId.get(ykiho);
            double[] stats = (hospitalId != null) ? ratingStatsMap.get(hospitalId) : null;
            double avgRating = (stats != null) ? stats[0] : 0.0;
            int reviewCount  = (stats != null) ? (int) stats[1] : 0;
            double reviewScore = avgRating / 5.0;

            // distanceScore: 반경 대비 거리 비례
            double distanceScore = Math.max(0.0, (radius - h.getDistance()) / (double) radius);

            // 가중 합산
            double score;
            if (reviewCount >= 10) {
                // Normal 가중치
                score = 0.35 * typeScore
                      + 0.30 * foreignScore
                      + 0.15 * reviewScore
                      + 0.20 * distanceScore;
            } else {
                // Cold Start 가중치 (리뷰 스코어 제외)
                score = 0.50 * typeScore
                      + 0.30 * foreignScore
                      + 0.20 * distanceScore;
            }

            Double avgRatingForDto = (reviewCount > 0) ? avgRating : null;
            result.put(ykiho, new ScoredHospital(score, avgRatingForDto, reviewCount));

            log.debug("스코어링 ykiho={} type={} foreign={} review={} distance={} → total={} (reviews={})",
                    ykiho, typeScore, foreignScore, reviewScore, distanceScore, score, reviewCount);
        }

        return result;
    }

    /**
     * typeScore 계산: 선호 종별 리스트에서의 선형 비례.
     * <p>rank = 리스트에서의 인덱스 (0 = 가장 선호). 리스트에 없으면 0.0.
     * <p>공식: (N-1-rank) / (N-1). N=1이면 1.0.
     */
    private double computeTypeScore(String clCd, List<String> preferredClCds) {
        int n = preferredClCds.size();
        if (n == 1) return 1.0;

        int rank = preferredClCds.indexOf(clCd);
        if (rank < 0) return 0.0;

        return (double)(n - 1 - rank) / (n - 1);
    }
}
