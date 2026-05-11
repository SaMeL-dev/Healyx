package com.smu.healyx.review.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

/**
 * 병원 상세 + 리뷰 목록 응답 (UI-HOS-08R / UI-REV-03 정합).
 *
 * <p>화면설계서 메모 — UI-REV-03은 UI-HOS-08R과 상단바 '리뷰' 문구만 다르고
 * 동일한 화면이므로 단일 엔드포인트로 두 화면을 모두 커버한다.
 *
 * <p>필드 그룹:
 * <ol>
 *   <li>병원 기본 정보 (UI-HOS-08R / UI-REV-03 정합) — 이름·타입·주소·전화·외국인 인증</li>
 *   <li>리뷰 집계 — 평균 별점·총 건수(페이징 인프라)</li>
 *   <li>본인 리뷰 여부 (UI-REV-03-P 정합) — 클릭 시점 중복 차단용</li>
 *   <li>페이징 리뷰 목록</li>
 * </ol>
 */
@Getter
@Builder
public class HospitalReviewResponse {

    // ── 병원 기본 정보 (UI-HOS-08R / UI-REV-03 정합) ────────────

    /** 병원명 */
    private String hospitalName;

    /** 병원 타입 (대학병원/병원/의원 등, hospitals.type) */
    private String hospitalType;

    /** 병원 주소 */
    private String address;

    /** 병원 전화번호 (없으면 null) */
    private String telephone;

    /** 외국인 환자 유치 의료기관 인증 여부 */
    private boolean foreignCertified;

    // ── 리뷰 집계 ──────────────────────────────────────────────

    /** 전체 리뷰 기준 평균 별점 (소수점 1자리, 리뷰 0건이면 0.0) */
    private double averageRating;

    /** 전체 리뷰 수 (리뷰 0건이면 0) — 페이징 분기용 */
    private long totalCount;

    // ── 본인 리뷰 여부 (UI-REV-03-P 정합) ──────────────────────

    /** 호출 사용자가 이 병원에 작성한 리뷰 존재 여부. 게스트는 false */
    private Boolean myReviewExists;

    /** 호출 사용자가 작성한 리뷰의 ID. 미작성/게스트는 null */
    private Long myReviewId;

    // ── 페이징 리뷰 목록 ──────────────────────────────────────

    /** 현재 페이지 리뷰 목록 (최신순) */
    private List<ReviewItemResponse> reviews;
}
