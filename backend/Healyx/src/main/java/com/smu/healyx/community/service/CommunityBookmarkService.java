package com.smu.healyx.community.service;

import com.smu.healyx.common.exception.AuthException;
import com.smu.healyx.community.dto.BookmarkedPostResponse;
import com.smu.healyx.community.repository.CommunityBookmarkRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CommunityBookmarkService {

    private final CommunityBookmarkRepository communityBookmarkRepository;

    /** 북마크한 게시글 목록 조회 — 북마크 등록 최신순 */
    @Transactional(readOnly = true)
    public List<BookmarkedPostResponse> getBookmarkedPosts(Long userId) {
        return communityBookmarkRepository.findBookmarkedPostsByUserId(userId)
                .stream()
                .map(BookmarkedPostResponse::from)
                .toList();
    }

    /** 북마크 삭제 — 본인 북마크인지 확인 후 삭제 */
    @Transactional
    public void deleteBookmark(Long userId, Long postId) {
        if (!communityBookmarkRepository.existsByPost_PostIdAndUser_UserId(postId, userId)) {
            throw new AuthException("BOOKMARK_NOT_FOUND", "해당 게시글의 북마크 내역이 없습니다.", HttpStatus.NOT_FOUND);
        }
        communityBookmarkRepository.deleteByPost_PostIdAndUser_UserId(postId, userId);
    }
}
