package com.smu.healyx.common.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Slf4j
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 1) // LocaleFilter 다음에 실행
public class LoggingFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain)
            throws ServletException, IOException {

        long startTime = System.currentTimeMillis();

        try {
            chain.doFilter(request, response);
        } finally {
            long responseTime = System.currentTimeMillis() - startTime;
            int status       = response.getStatus();
            String path      = request.getRequestURI();
            String method    = request.getMethod();

            // 5XX 서버 에러 → ERROR 레벨
            if (status >= 500) {
                log.error("api_path={} method={} status_code={} response_time_ms={}",
                        path, method, status, responseTime);
            // 4XX 클라이언트 에러 → WARN 레벨
            } else if (status >= 400) {
                log.warn("api_path={} method={} status_code={} response_time_ms={}",
                        path, method, status, responseTime);
            // 정상 응답 → INFO 레벨
            } else {
                log.info("api_path={} method={} status_code={} response_time_ms={}",
                        path, method, status, responseTime);
            }
        }
    }
}
