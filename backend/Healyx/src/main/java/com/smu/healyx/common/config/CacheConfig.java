package com.smu.healyx.common.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

/**
 * Caffeine 인메모리 캐시 설정.
 *
 * <p>캐시명별 spec:
 * <ul>
 *   <li>costReferenceByIcd  : TTL 24h, maxSize 1000</li>
 *   <li>costReferenceByDept : TTL 24h, maxSize 100</li>
 *   <li>costAdjustment      : TTL 24h, maxSize 500</li>
 *   <li>regionAdjustment    : TTL 24h, maxSize 500</li>
 *   <li>hospitalTypeAdjustment: TTL 24h, maxSize 50</li>
 *   <li>userById            : TTL 30s, maxSize 200 (user 정보 변경 반영 보장)</li>
 * </ul>
 *
 * <p>마스터 데이터는 운영 중 변경 빈도 매우 낮으므로 TTL 24h로 충분.
 * 데이터 갱신 필요 시 애플리케이션 재배포.
 */
@Configuration
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager manager = new CaffeineCacheManager();
        manager.registerCustomCache("costReferenceByIcd",
                Caffeine.newBuilder()
                        .expireAfterWrite(24, TimeUnit.HOURS)
                        .maximumSize(1000)
                        .build());
        manager.registerCustomCache("costReferenceByDept",
                Caffeine.newBuilder()
                        .expireAfterWrite(24, TimeUnit.HOURS)
                        .maximumSize(100)
                        .build());
        manager.registerCustomCache("costAdjustment",
                Caffeine.newBuilder()
                        .expireAfterWrite(24, TimeUnit.HOURS)
                        .maximumSize(500)
                        .build());
        manager.registerCustomCache("regionAdjustment",
                Caffeine.newBuilder()
                        .expireAfterWrite(24, TimeUnit.HOURS)
                        .maximumSize(500)
                        .build());
        manager.registerCustomCache("hospitalTypeAdjustment",
                Caffeine.newBuilder()
                        .expireAfterWrite(24, TimeUnit.HOURS)
                        .maximumSize(50)
                        .build());
        manager.registerCustomCache("userById",
                Caffeine.newBuilder()
                        .expireAfterWrite(30, TimeUnit.SECONDS)
                        .maximumSize(200)
                        .build());
        return manager;
    }
}
