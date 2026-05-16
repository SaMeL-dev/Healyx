package com.smu.healyx.community.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.community.domain.CommunityLike;
import com.smu.healyx.community.domain.CommunityPost;
import com.smu.healyx.community.dto.ToggleLikeResponse;
import com.smu.healyx.community.repository.CommunityLikeRepository;
import com.smu.healyx.community.repository.CommunityPostRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CommunityLikeService {

    private final CommunityLikeRepository likeRepository;
    private final CommunityPostRepository postRepository;
    private final UserRepository userRepository;

    /** HX_COM_012 — 좋아요 토글 */
    @Transactional
    public ToggleLikeResponse toggleLike(Long userId, Long postId) {
        CommunityPost post = postRepository.findById(postId)
                .orElseThrow(() -> new AuthException("POST_NOT_FOUND", "게시글을 찾을 수 없습니다.", HttpStatus.NOT_FOUND));

        boolean liked;
        if (likeRepository.existsByPost_PostIdAndUser_UserId(postId, userId)) {
            likeRepository.deleteByPost_PostIdAndUser_UserId(postId, userId);
            post.decreaseLikeCount();
            liked = false;
        } else {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new AuthException("USER_NOT_FOUND", "사용자 정보를 찾을 수 없습니다.", HttpStatus.NOT_FOUND));
            likeRepository.save(CommunityLike.builder().post(post).user(user).build());
            post.increaseLikeCount();
            liked = true;
        }

        return new ToggleLikeResponse(liked, post.getLikeCount());
    }
}
