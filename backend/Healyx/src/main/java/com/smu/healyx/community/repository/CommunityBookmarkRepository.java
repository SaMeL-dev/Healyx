package com.smu.healyx.community.repository;

import com.smu.healyx.community.domain.CommunityBookmark;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface CommunityBookmarkRepository extends JpaRepository<CommunityBookmark, Long> {
    boolean existsByPost_PostIdAndUser_UserId(Long postId, Long userId);
    void deleteByPost_PostIdAndUser_UserId(Long postId, Long userId);
    List<CommunityBookmark> findByUser_UserId(Long userId);

    // 북마크 목록 조회 — post·user 한 번에 fetch, 북마크 최신순 정렬
    @Query("SELECT b FROM CommunityBookmark b JOIN FETCH b.post p JOIN FETCH p.user WHERE b.user.userId = :userId ORDER BY b.createdAt DESC")
    List<CommunityBookmark> findBookmarkedPostsByUserId(@Param("userId") Long userId);
}
