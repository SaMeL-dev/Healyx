package com.smu.healyx.common.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Locale;
import java.util.Set;

/**
 * Accept-Language 헤더를 파싱하여 LocaleContextHolder에 locale을 설정하는 필터.
 * 지원 언어: ko, en, zh, vi, th, ja (이 외는 기본값 ko 적용)
 */
@Component
public class LocaleFilter extends OncePerRequestFilter {

    private static final Set<String> SUPPORTED = Set.of("ko", "en", "zh", "vi", "th", "ja");

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String lang = request.getHeader("Accept-Language");
        Locale locale = Locale.KOREAN; // 기본값

        if (lang != null && !lang.isBlank()) {
            String code = lang.split("[,;\\-]")[0].trim().toLowerCase();
            if (SUPPORTED.contains(code)) {
                // zh는 zh-CN으로 매핑하여 MessageSource가 zh 파일을 탐색하도록 함
                locale = "zh".equals(code) ? Locale.forLanguageTag("zh-CN") : Locale.forLanguageTag(code);
            }
        }

        LocaleContextHolder.setLocale(locale);
        try {
            chain.doFilter(request, response);
        } finally {
            LocaleContextHolder.resetLocaleContext();
        }
    }
}
