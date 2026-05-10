package com.smu.healyx.user.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class PushSettingRequest {

    @NotNull(message = "pushEnabled는 필수입니다.")
    private Boolean pushEnabled;
}
