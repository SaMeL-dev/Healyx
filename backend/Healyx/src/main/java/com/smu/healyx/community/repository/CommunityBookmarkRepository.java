package com.smu.healyx.community.repository;

import com.smu.healyx.community.domain.CommunityBookmark;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface CommunityBookmarkRepository extends JpaRepository<CommunityBookmark, Long> {
    boolean existsByPost_PostIdAndUser_UserId(Long postId, Long userId);
    void deleteByPost_PostIdAndUser_UserId(Long postId, Long userId);
    List<CommunityBookmark> findByUser_UserId(Long userId);
}
