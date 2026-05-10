package com.smu.healyx.community.repository;

import com.smu.healyx.community.domain.CommunityComment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface CommunityCommentRepository extends JpaRepository<CommunityComment, Long> {
    List<CommunityComment> findByPost_PostIdAndIsDeletedFalse(Long postId);
    List<CommunityComment> findByParentComment_CommentIdAndIsDeletedFalse(Long parentCommentId);
    List<CommunityComment> findByUser_UserIdAndIsDeletedFalse(Long userId);

    // 내가 쓴 댓글 — post JOIN FETCH(N+1 방지), 삭제 제외, 최신순
    @Query("SELECT c FROM CommunityComment c JOIN FETCH c.post WHERE c.user.userId = :userId AND c.isDeleted = false ORDER BY c.createdAt DESC")
    List<CommunityComment> findMyCommentsWithPost(@Param("userId") Long userId);

    // 대댓글 전체 삭제 (부모 댓글 하드 삭제 전 선행 처리)
    void deleteByParentComment_CommentId(Long commentId);
}
