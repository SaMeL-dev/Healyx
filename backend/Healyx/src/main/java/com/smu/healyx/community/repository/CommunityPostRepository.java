package com.smu.healyx.community.repository;

import com.smu.healyx.community.domain.CommunityPost;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface CommunityPostRepository extends JpaRepository<CommunityPost, Long> {
    List<CommunityPost> findByUser_UserId(Long userId);
    List<CommunityPost> findAll();

    // 내가 쓴 게시글 — 최신순
    List<CommunityPost> findByUser_UserIdOrderByCreatedAtDesc(Long userId);

    // 게시글 목록·검색 (블라인드 제외)
    @Query("SELECT p FROM CommunityPost p WHERE p.isBlinded = false " +
           "AND (:keyword = '' OR " +
           "     ((:searchField = 'title' OR :searchField = 'all') AND LOWER(p.title) LIKE LOWER(CONCAT('%', :keyword, '%'))) OR " +
           "     ((:searchField = 'content' OR :searchField = 'all') AND LOWER(p.content) LIKE LOWER(CONCAT('%', :keyword, '%'))))")
    Page<CommunityPost> searchPosts(@Param("keyword") String keyword,
                                     @Param("searchField") String searchField,
                                     Pageable pageable);

    // 조회수 +1
    @Modifying
    @Query("UPDATE CommunityPost p SET p.viewCount = p.viewCount + 1 WHERE p.postId = :postId")
    void incrementViewCount(@Param("postId") Long postId);
}