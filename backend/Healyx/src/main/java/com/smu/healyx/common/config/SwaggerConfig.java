package com.smu.healyx.common.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.media.StringSchema;
import io.swagger.v3.oas.models.parameters.Parameter;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springdoc.core.customizers.GlobalOpenApiCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class SwaggerConfig {

    private static final String SECURITY_SCHEME_NAME = "BearerAuth";

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("HEALYX API")
                        .description("한국 체류 외국인을 위한 AI 기반 병원 추천 및 의료비 예측 플랫폼")
                        .version("v1.0"))
                .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME_NAME))
                .components(new Components()
                        .addSecuritySchemes(SECURITY_SCHEME_NAME,
                                new SecurityScheme()
                                        .name(SECURITY_SCHEME_NAME)
                                        .type(SecurityScheme.Type.HTTP)
                                        .scheme("bearer")
                                        .bearerFormat("JWT")));
    }

    @Bean
    public GlobalOpenApiCustomizer acceptLanguageHeaderCustomizer() {
        return openApi -> openApi.getPaths().values().forEach(pathItem ->
                pathItem.readOperations().forEach(op ->
                        op.addParametersItem(new Parameter()
                                .in("header")
                                .name("Accept-Language")
                                .description("[테스트 전용] 응답 언어를 지정합니다 (ko·en·zh·vi·th·ja). " +
                                        "프로덕션에서는 Flutter 앱이 사용자 언어 설정에 따라 자동으로 전송하므로 별도 입력 불필요.")
                                .required(false)
                                .schema(new StringSchema()
                                        ._enum(List.of("ko", "en", "zh", "vi", "th", "ja"))
                                        ._default("ko")))));
    }
}
