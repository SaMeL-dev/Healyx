package com.smu.healyx.common.config;

import com.smu.healyx.common.security.JwtAuthenticationFilter;
import com.smu.healyx.common.security.JwtProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtProvider jwtProvider;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
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
                // 게스트 허용: 의료 번역
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
                // 그 외는 인증 필요
                .anyRequest().authenticated()
            )
            .addFilterBefore(new JwtAuthenticationFilter(jwtProvider),
                             UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
