package com.smu.healyx.community;

import com.smu.healyx.community.domain.CommunityPost;
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
public class CommunityPostRepositoryTest {

    @Autowired private CommunityPostRepository communityPostRepository;
    @Autowired private UserRepository userRepository;

    @Test
    void 게시글_저장_및_조회() {
        User user = userRepository.save(User.builder()
                .username("postuser1")
                .passwordHash("hash")
                .realName("게시글유저")
                .email("post@healyx.com")
                .nickname("게시글닉")
                .preferredLanguage("en")
                .build());

        communityPostRepository.save(CommunityPost.builder()
                .user(user)
                .category("자유")
                .title("첫 게시글")
                .content("안녕하세요")
                .build());

        List<CommunityPost> result = communityPostRepository
                .findByUser_UserIdAndIsDeletedFalse(user.getUserId());

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getTitle()).isEqualTo("첫 게시글");
    }

    @Test
    void 카테고리별_게시글_조회() {
        User user = userRepository.save(User.builder()
                .username("postuser2")
                .passwordHash("hash")
                .realName("카테고리유저")
                .email("cat@healyx.com")
                .nickname("카테고리닉")
                .preferredLanguage("en")
                .build());

        communityPostRepository.save(CommunityPost.builder()
                .user(user)
                .category("정보")
                .title("정보 게시글")
                .content("유용한 정보")
                .build());

        List<CommunityPost> result = communityPostRepository
                .findByCategoryAndIsDeletedFalse("정보");

        assertThat(result).isNotEmpty();
        assertThat(result.get(0).getCategory()).isEqualTo("정보");
    }
}
