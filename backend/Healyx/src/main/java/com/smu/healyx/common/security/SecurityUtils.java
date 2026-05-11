package com.smu.healyx.common.security;

import org.springframework.security.core.Authentication;

/**
 * JWT 인증 유틸리티.
 *
 * JWT 필터 구현 완료 후:
 *   JWT claim의 userId(Long)를 Authentication principal로 설정하면
 *   extractUserId()가 그대로 동작합니다.
 *
 * 예시 (JWT 필터 내):
 *   Long userId = jwtProvider.getUserId(token);
 *   UsernamePasswordAuthenticationToken auth =
 *       new UsernamePasswordAuthenticationToken(userId, null, authorities);
 *   SecurityContextHolder.getContext().setAuthentication(auth);
 */
public final class SecurityUtils {

    private SecurityUtils() {}

    /**
     * 인증 필수 엔드포인트에서 userId를 추출한다.
     * 인증 정보가 없거나 형식이 어긋나면 IllegalStateException 발생.
     */
    public static Long extractUserId(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new IllegalStateException("인증 정보가 없습니다.");
        }

        Object principal = authentication.getPrincipal();
        if (principal instanceof Long id) {
            return id;
        }

        // JWT 필터가 구현되면 이 경로에 도달하지 않습니다.
        throw new IllegalStateException("JWT 필터 미구현: 인증 정보에서 userId를 추출할 수 없습니다.");
    }

    /**
     * 게스트 허용 엔드포인트에서 userId를 추출한다.
     * 비로그인(Authentication == null)이거나 익명 인증 상태면 null 반환,
     * 정상 로그인 상태면 userId 반환.
     *
     * <p>SecurityConfig상 permitAll로 열린 GET 엔드포인트에서 사용:
     * <ul>
     *   <li>{@code GET /api/reviews/hospitals/{ykiho}} — 본인 리뷰 식별 (UI-REV-03-P)</li>
     *   <li>향후 게스트 허용 + 개인화 응답이 필요한 엔드포인트에 재사용</li>
     * </ul>
     */
    public static Long extractUserIdNullable(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        Object principal = authentication.getPrincipal();
        return (principal instanceof Long id) ? id : null;
    }
}
