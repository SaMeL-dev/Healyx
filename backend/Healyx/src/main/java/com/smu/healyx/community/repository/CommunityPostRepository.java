package com.smu.healyx.community.repository;

import com.smu.healyx.community.domain.CommunityPost;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface CommunityPostRepository extends JpaRepository<CommunityPost, Long> {
    List<CommunityPost> findByUser_UserId(Long userId);
    List<CommunityPost> findAll();

    // 내가 쓴 게시글 — 최신순
    List<CommunityPost> findByUser_UserIdOrderByCreatedAtDesc(Long userId);
}