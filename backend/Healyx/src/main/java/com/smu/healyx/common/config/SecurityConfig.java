package com.smu.healyx.common.config;

import com.smu.healyx.common.filter.LocaleFilter;
import com.smu.healyx.common.security.JwtAuthenticationFilter;
import com.smu.healyx.common.security.JwtProvider;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.List;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtProvider jwtProvider;
    private final LocaleFilter localeFilter;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            // JWT 없이 보호된 엔드포인트 접근 시 403 대신 401 반환
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint((request, response, authException) ->
                    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized")))
            .authorizeHttpRequests(auth -> auth
                // CORS preflight 허용
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                // 인증 API (회원가입, 로그인, 토큰 재발급, 아이디 찾기, 비밀번호 재설정, 중복 확인)
                .requestMatchers("/api/auth/register",
                                 "/api/auth/login",
                                 "/api/auth/refresh",
                                 "/api/auth/find-id",
                                 "/api/auth/verify-reset-password",
                                 "/api/auth/reset-password",
                                 "/api/auth/check-email",
                                 "/api/auth/check-username").permitAll()
                // 게스트 허용: 병원 찾기
                .requestMatchers("/api/hospitals/**").permitAll()
                // 병원별 리뷰 조회: 비로그인 허용 / 나머지 리뷰 API: 인증 필요
                .requestMatchers(HttpMethod.GET, "/api/reviews/hospitals/**").permitAll()
                // 게스트 허용: 의료 번역 (보관함 조회·삭제 제외 — 로그인 필요)
                .requestMatchers("/api/translations/archive", "/api/translations/archive/**").authenticated()
                .requestMatchers("/api/translation/**", "/api/translations/**").permitAll()
                // 게스트 허용: GPT 증상 분석
                .requestMatchers("/api/gpt/**").permitAll()
                // 게스트 허용: Google Vision OCR
                .requestMatchers("/api/vision/**").permitAll()
                // 이메일 인증 (회원가입·아이디 찾기·비밀번호 재설정)
                .requestMatchers("/api/email/**").permitAll()
                // FCM 테스트
                .requestMatchers("/api/fcm/**").permitAll()
                // 병원 찾기 + 의료비 예측 Agent (게스트 허용)
                .requestMatchers("/api/agent/**").permitAll()
                // Swagger UI
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                // Application Load Balancer
                .requestMatchers("/actuator/health").permitAll()
                // Grafana Prometheus 메트릭
                .requestMatchers("/actuator/prometheus").permitAll()
                // 커뮤니티 게시글 조회 — 게스트 허용
                .requestMatchers(HttpMethod.GET, "/api/community/posts", "/api/community/posts/**").permitAll()
                // 커뮤니티 번역 엔드포인트 — 게스트 허용 (COM-011)
                .requestMatchers(HttpMethod.GET, "/api/community/posts/*/translate").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/community/comments/*/translate").permitAll()
                // 그 외는 인증 필요
                .anyRequest().authenticated()
            )
            .addFilterBefore(localeFilter, UsernamePasswordAuthenticationFilter.class)
            .addFilterBefore(new JwtAuthenticationFilter(jwtProvider),
                             UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(List.of("https://jwejweiya.com", "http://localhost:8080"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
