package com.smu.healyx.common.config;

import org.springframework.context.MessageSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.support.ReloadableResourceBundleMessageSource;

import java.util.Locale;

/**
 * 다국어 메시지 소스 설정.
 * messages/errors_{locale}.properties, messages/business_{locale}.properties 로드.
 * 기본 locale: ko (한국어)
 */
@Configuration
public class MessageSourceConfig {

    @Bean
    public MessageSource messageSource() {
        ReloadableResourceBundleMessageSource ms = new ReloadableResourceBundleMessageSource();
        ms.setBasenames("classpath:messages/errors", "classpath:messages/business");
        ms.setDefaultEncoding("UTF-8");
        ms.setDefaultLocale(Locale.KOREAN);
        ms.setFallbackToSystemLocale(false);
        return ms;
    }
}
