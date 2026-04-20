package com.smu.healyx.community.repository;

import com.smu.healyx.community.domain.CommunityLike;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CommunityLikeRepository extends JpaRepository<CommunityLike, Long> {
    boolean existsByPost_PostIdAndUser_UserId(Long postId, Long userId);
    void deleteByPost_PostIdAndUser_UserId(Long postId, Long userId);
    int countByPost_PostId(Long postId);
}
