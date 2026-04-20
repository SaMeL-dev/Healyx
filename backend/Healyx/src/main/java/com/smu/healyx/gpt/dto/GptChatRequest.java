package com.smu.healyx.gpt.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

/** OpenAI Chat Completions API 요청 DTO */
@Getter
@AllArgsConstructor
public class GptChatRequest {

    private String model;
    private List<Message> messages;

    @JsonProperty("max_completion_tokens")
    private int maxTokens;

    private double temperature;

    @Getter
    @AllArgsConstructor
    public static class Message {
        private String role;
        private String content;
    }
}
