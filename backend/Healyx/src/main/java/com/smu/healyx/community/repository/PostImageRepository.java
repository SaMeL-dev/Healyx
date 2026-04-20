package com.smu.healyx.community.repository;

import com.smu.healyx.community.domain.PostImage;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface PostImageRepository extends JpaRepository<PostImage, Long> {
    List<PostImage> findByPost_PostIdOrderBySortOrderAsc(Long postId);
}
