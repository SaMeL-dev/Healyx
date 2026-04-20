package com.smu.healyx.community;

import com.smu.healyx.community.domain.CommunityBookmark;
import com.smu.healyx.community.domain.CommunityPost;
import com.smu.healyx.community.repository.CommunityBookmarkRepository;
import com.smu.healyx.community.repository.CommunityPostRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("local")
public class CommunityBookmarkRepositoryTest {

    @Autowired private CommunityBookmarkRepository communityBookmarkRepository;
    @Autowired private CommunityPostRepository communityPostRepository;
    @Autowired private UserRepository userRepository;

    @Test
    void 북마크_저장_및_조회() {
        User user = userRepository.save(User.builder()
                .username("bookmarkuser1").passwordHash("hash")
                .realName("북마크유저").email("bookmark@healyx.com")
                .nickname("북마크닉").preferredLanguage("en")
                .build());

        CommunityPost post = communityPostRepository.save(CommunityPost.builder()
                .user(user).category("자유")
                .title("북마크테스트").content("내용")
                .build());

        communityBookmarkRepository.save(CommunityBookmark.builder()
                .post(post).user(user).build());

        assertThat(communityBookmarkRepository
                .existsByPost_PostIdAndUser_UserId(post.getPostId(), user.getUserId())).isTrue();

        List<CommunityBookmark> result = communityBookmarkRepository
                .findByUser_UserId(user.getUserId());
        assertThat(result).hasSize(1);
    }
}
