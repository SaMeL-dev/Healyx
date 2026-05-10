package com.smu.healyx.user.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.dto.MyProfileResponse;
import com.smu.healyx.user.dto.ProfileUpdateRequest;
import com.smu.healyx.user.dto.UserProfileDto;
import com.smu.healyx.user.repository.UserRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Objects;

@Service
@RequiredArgsConstructor
public class UserProfileService {

    private final UserRepository userRepository;

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

    /** 선호 언어 업데이트 */
    @Transactional
    public void updateLanguage(Long userId, String languageCode) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new AuthException("USER_NOT_FOUND", "사용자를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));
        user.updateLanguage(languageCode);
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

    /** 자동 로그인 및 프로필 화면용 전체 프로필 조회 */
    @Transactional(readOnly = true)
    public MyProfileResponse getMyProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("사용자를 찾을 수 없습니다. id=" + userId));

        return MyProfileResponse.builder()
                .userId(user.getUserId())
                .username(user.getUsername())
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
