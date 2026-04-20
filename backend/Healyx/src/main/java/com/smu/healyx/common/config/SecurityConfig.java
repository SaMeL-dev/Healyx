package com.smu.healyx.common.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // 게스트 허용: 병원 찾기
                .requestMatchers("/api/hospitals/**").permitAll()
                // 게스트 허용: 의료 번역 (컨트롤러 경로: /api/translation/**)
                .requestMatchers("/api/translation/**").permitAll()
                // 게스트 허용: GPT 증상 분석
                .requestMatchers("/api/gpt/**").permitAll()
                // 게스트 허용: Google Vision OCR
                .requestMatchers("/api/vision/**").permitAll()
                // 이메일 인증 (회원가입·아이디 찾기·비밀번호 재설정)
                .requestMatchers("/api/email/**").permitAll()
                // FCM 테스트
                .requestMatchers("/api/fcm/**").permitAll()
                // Swagger UI
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                // 그 외는 인증 필요
                .anyRequest().authenticated()
            );

        return http.build();
    }
}