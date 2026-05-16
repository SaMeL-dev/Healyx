package com.smu.healyx.community.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.gpt.dto.GptChatRequest;
import com.smu.healyx.gpt.service.GptService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class ContentFilterService {

    private final GptService gptService;

    private static final String MODEL = "gpt-5.4-mini";

    /**
     * 게시글/댓글 내용을 GPT로 필터링.
     * 차단 판정 시 CLEANBOT_BLOCKED(422). GPT 오류 시 fail-open.
     *
     * @param title 게시글 제목 (댓글이면 null)
     * @param content 본문 또는 댓글 내용
     */
    public void filterWithLLM(String title, String content) {
        String text = (title != null && !title.isBlank() ? title + "\n" : "") + content;

        String systemPrompt = """
                당신은 커뮤니티 콘텐츠 필터링 AI입니다.
                아래 텍스트에 욕설, 혐오 발언, 스팸, 허위사실이 포함되어 있으면 "true", 없으면 "false"만 답하세요.
                다른 텍스트는 절대 출력하지 마세요.
                """;

        GptChatRequest request = new GptChatRequest(
                MODEL,
                List.of(
                        new GptChatRequest.Message("system", systemPrompt),
                        new GptChatRequest.Message("user", text)
                ),
                10,
                0.0
        );

        try {
            String answer = gptService.callChatCompletion(request).getFirstContent();
            if (answer != null && answer.trim().equalsIgnoreCase("true")) {
                throw new AuthException("CLEANBOT_BLOCKED",
                        "커뮤니티 규칙에 위반되는 내용이 감지되었습니다.",
                        HttpStatus.UNPROCESSABLE_ENTITY);
            }
        } catch (AuthException e) {
            throw e;
        } catch (Exception e) {
            log.warn("클린봇 GPT 호출 실패, fail-open 처리: {}", e.getMessage());
        }
    }
}
