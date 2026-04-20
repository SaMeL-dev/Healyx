package com.smu.healyx.community;

import com.smu.healyx.community.domain.CommunityPost;
import com.smu.healyx.community.domain.PostImage;
import com.smu.healyx.community.repository.CommunityPostRepository;
import com.smu.healyx.community.repository.PostImageRepository;
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
public class PostImageRepositoryTest {

    @Autowired private PostImageRepository postImageRepository;
    @Autowired private CommunityPostRepository communityPostRepository;
    @Autowired private UserRepository userRepository;

    @Test
    void 게시글이미지_저장_및_순서조회() {
        User user = userRepository.save(User.builder()
                .username("imgpostuser1")
                .passwordHash("hash")
                .realName("이미지게시글유저")
                .email("imgpost@healyx.com")
                .nickname("이미지게시닉")
                .preferredLanguage("en")
                .build());

        CommunityPost post = communityPostRepository.save(CommunityPost.builder()
                .user(user)
                .category("자유")
                .title("이미지 게시글")
                .content("이미지 있어요")
                .build());

        postImageRepository.save(PostImage.builder()
                .post(post).imageUrl("https://s3.test/img2.jpg").sortOrder(1).build());
        postImageRepository.save(PostImage.builder()
                .post(post).imageUrl("https://s3.test/img1.jpg").sortOrder(0).build());

        List<PostImage> result = postImageRepository
                .findByPost_PostIdOrderBySortOrderAsc(post.getPostId());

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getSortOrder()).isEqualTo(0);
    }
}
