package com.smu.healyx.user.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.common.service.S3UploadService;
import com.smu.healyx.community.repository.CommunityCommentRepository;
import com.smu.healyx.community.repository.PostImageRepository;
import com.smu.healyx.review.repository.ReviewImageRepository;
import com.smu.healyx.translation.domain.MedicalTranslation;
import com.smu.healyx.translation.repository.MedicalTranslationRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.dto.MyProfileResponse;
import com.smu.healyx.user.dto.ProfileUpdateRequest;
import com.smu.healyx.user.dto.PushSettingRequest;
import com.smu.healyx.user.dto.UserProfileDto;
import com.smu.healyx.user.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.List;
import java.util.Objects;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserProfileService {

    private final UserRepository userRepository;
    private final StringRedisTemplate redisTemplate;
    private final CommunityCommentRepository communityCommentRepository;
    private final ReviewImageRepository reviewImageRepository;
    private final PostImageRepository postImageRepository;
    private final MedicalTranslationRepository medicalTranslationRepository;
    private final S3UploadService s3UploadService;

    @Transactional(readOnly = true)
    public UserProfileDto getProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다. id=" + userId));

        return UserProfileDto.builder()
                .age(user.getAge() != null ? user.getAge() : 0)
                .gender(user.getGender())
                .insured(user.isHasHealthInsurance())
                .build();
    }

    /** 알림 설정 변경 */
    @Transactional
    public void updatePushSetting(Long userId, boolean pushEnabled) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));
        user.updatePushSetting(pushEnabled);
    }

    /** 선호 언어 업데이트 */
    @Transactional
    public void updateLanguage(Long userId, String languageCode) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));
        user.updateLanguage(languageCode);
    }

    /** 회원 탈퇴 — hard delete, Redis 삭제는 DB 커밋 완료 후 afterCommit() 훅에서 실행 */
    @Transactional
    public void withdraw(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        // mention_user_id FK는 cascade 미적용 — DB 삭제 전 null 처리
        communityCommentRepository.clearMentionUser(userId);

        // S3 파일 삭제 (DB 삭제 전 선행 — 고아 파일 방지)
        reviewImageRepository.findByReview_User_UserId(userId)
                .forEach(img -> deleteS3Quietly(img.getImageUrl()));
        postImageRepository.findByPost_User_UserId(userId)
                .forEach(img -> deleteS3Quietly(img.getImageUrl()));
        List<MedicalTranslation> translations = medicalTranslationRepository.findByUser_UserId(userId);
        translations.forEach(t -> {
            deleteS3Quietly(t.getImageUrl());
            deleteS3Quietly(t.getTranslatedImageUrl());
        });

        // User cascade: reviews·posts·comments·bookmarks·likes·notifications·translations·reports
        userRepository.delete(user);

        // DB 커밋 완료 후 Redis 삭제 — 커밋 실패 시 Redis 미변경 보장
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                redisTemplate.delete("user:" + userId + ":refresh_token");
                log.info("회원 탈퇴 완료: userId={}", userId);
            }
        });
    }

    /** 프로필 일괄 수정 (실명·이메일·닉네임·건강보험 가입 상태) */
    @Transactional
    public void updateProfile(Long userId, ProfileUpdateRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        // 이메일이 변경된 경우에만 다른 사용자의 중복 여부 확인
        if (!Objects.equals(user.getEmail(), request.getEmail()) &&
                userRepository.existsByEmailAndUserIdNot(request.getEmail(), userId)) {
            throw new AuthException("EMAIL_ALREADY_EXISTS", "이미 사용 중인 이메일입니다.", HttpStatus.CONFLICT);
        }

        user.updateProfile(
                request.getRealName(),
                request.getEmail(),
                request.getNickname(),
                "insured".equals(request.getInsuranceStatus())
        );
    }

    private void deleteS3Quietly(String url) {
        if (url == null || url.isBlank()) return;
        try {
            s3UploadService.delete(url);
        } catch (Exception e) {
            log.warn("S3 파일 삭제 실패 (무시됨): url={}", url, e);
        }
    }

    /** 자동 로그인 및 프로필 화면용 전체 프로필 조회 */
    @Transactional(readOnly = true)
    public MyProfileResponse getMyProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다. id=" + userId));

        return MyProfileResponse.builder()
                .userId(user.getUserId())
                .realName(user.getUsername())
                .nickname(user.getNickname())
                .name(user.getRealName())
                .email(user.getEmail())
                .gender(user.getGender())
                .birthDate(user.getBirthDate())
                .age(user.getAge())
                .insuranceStatus(user.isHasHealthInsurance())
                .preferredLanguage(user.getPreferredLanguage())
                .pushEnabled(user.isPushEnabled())
                .build();
    }
}
