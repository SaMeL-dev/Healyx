package com.smu.healyx.community.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.community.domain.CommunityComment;
import com.smu.healyx.community.domain.CommunityPost;
import com.smu.healyx.community.domain.Report;
import com.smu.healyx.community.dto.ReportRequest;
import com.smu.healyx.community.repository.CommunityCommentRepository;
import com.smu.healyx.community.repository.CommunityPostRepository;
import com.smu.healyx.community.repository.ReportRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReportService {

    private final ReportRepository reportRepository;
    private final UserRepository userRepository;
    private final CommunityPostRepository postRepository;
    private final CommunityCommentRepository commentRepository;

    /** HX_COM_009 — 신고 접수 + 5건 누적 시 자동 블라인드 */
    @Transactional
    public void reportContent(Long reporterId, ReportRequest request) {
        User reporter = userRepository.findById(reporterId)
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND",
                        "사용자 정보를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        Long targetAuthorId = resolveTargetAuthorId(request.getTargetType(), request.getTargetId());
        if (targetAuthorId.equals(reporterId)) {
            throw new AuthException("SELF_REPORT_NOT_ALLOWED",
                    "본인의 게시글/댓글은 신고할 수 없습니다.", HttpStatus.BAD_REQUEST);
        }

        if (reportRepository.existsByReporter_UserIdAndTargetTypeAndTargetId(
                reporterId, request.getTargetType(), request.getTargetId())) {
            throw new AuthException("REPORT_DUPLICATE",
                    "이미 신고한 대상입니다.", HttpStatus.CONFLICT);
        }

        reportRepository.save(Report.builder()
                .reporter(reporter)
                .targetType(request.getTargetType())
                .targetId(request.getTargetId())
                .reason(request.getReason())
                .build());

        long count = reportRepository.countByTargetTypeAndTargetId(
                request.getTargetType(), request.getTargetId());

        if (count >= 5) {
            applyAutoBlind(request.getTargetType(), request.getTargetId());
        }
    }

    private Long resolveTargetAuthorId(String targetType, Long targetId) {
        if ("POST".equals(targetType)) {
            CommunityPost post = postRepository.findById(targetId)
                    .orElseThrow(() -> new AuthException("POST_NOT_FOUND",
                            "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));
            return post.getUser().getUserId();
        } else if ("COMMENT".equals(targetType)) {
            CommunityComment comment = commentRepository.findById(targetId)
                    .orElseThrow(() -> new AuthException("COMMENT_NOT_FOUND",
                            "댓글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));
            return comment.getUser().getUserId();
        }
        throw new AuthException("INVALID_TARGET_TYPE",
                "신고 대상 유형이 올바르지 않습니다. (POST 또는 COMMENT)", HttpStatus.BAD_REQUEST);
    }

    private void applyAutoBlind(String targetType, Long targetId) {
        if ("POST".equals(targetType)) {
            postRepository.findById(targetId).ifPresent(CommunityPost::blind);
        } else if ("COMMENT".equals(targetType)) {
            commentRepository.findById(targetId).ifPresent(CommunityComment::softDelete);
        }
    }
}
