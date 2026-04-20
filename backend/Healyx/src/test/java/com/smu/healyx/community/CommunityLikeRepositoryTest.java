package com.smu.healyx.community;

import com.smu.healyx.community.domain.CommunityLike;
import com.smu.healyx.community.domain.CommunityPost;
import com.smu.healyx.community.repository.CommunityLikeRepository;
import com.smu.healyx.community.repository.CommunityPostRepository;
import com.smu.healyx.user.domain.User;
import com.smu.healyx.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("local")
public class CommunityLikeRepositoryTest {

    @Autowired private CommunityLikeRepository communityLikeRepository;
    @Autowired private CommunityPostRepository communityPostRepository;
    @Autowired private UserRepository userRepository;

    @Test
    void 좋아요_저장_및_중복확인() {
        User user = userRepository.save(User.builder()
                .username("likeuser1").passwordHash("hash")
                .realName("좋아요유저").email("like@healyx.com")
                .nickname("좋아요닉").preferredLanguage("en")
                .build());

        CommunityPost post = communityPostRepository.save(CommunityPost.builder()
                .user(user).category("자유")
                .title("좋아요테스트").content("내용")
                .build());

        communityLikeRepository.save(CommunityLike.builder()
                .post(post).user(user).build());

        assertThat(communityLikeRepository
                .existsByPost_PostIdAndUser_UserId(post.getPostId(), user.getUserId())).isTrue();
        assertThat(communityLikeRepository.countByPost_PostId(post.getPostId())).isEqualTo(1);
    }
}
