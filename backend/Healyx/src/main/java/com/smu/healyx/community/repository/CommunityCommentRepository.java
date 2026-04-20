package com.smu.healyx.community.repository;

import com.smu.healyx.community.domain.CommunityComment;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface CommunityCommentRepository extends JpaRepository<CommunityComment, Long> {
    List<CommunityComment> findByPost_PostIdAndIsDeletedFalse(Long postId);
    List<CommunityComment> findByParentComment_CommentIdAndIsDeletedFalse(Long parentCommentId);
    List<CommunityComment> findByUser_UserIdAndIsDeletedFalse(Long userId);
}
