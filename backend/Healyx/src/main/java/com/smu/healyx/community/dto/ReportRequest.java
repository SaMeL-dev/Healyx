package com.smu.healyx.community.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

@Getter
public class ReportRequest {

    @NotNull
    private String targetType;

    @NotNull
    private Long targetId;

    @NotBlank
    private String reason;
}
