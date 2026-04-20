package com.smu.healyx.community.repository;

import com.smu.healyx.community.domain.CommunityPost;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface CommunityPostRepository extends JpaRepository<CommunityPost, Long> {
    List<CommunityPost> findByUser_UserIdAndIsDeletedFalse(Long userId);
    List<CommunityPost> findByCategoryAndIsDeletedFalse(String category);
}
