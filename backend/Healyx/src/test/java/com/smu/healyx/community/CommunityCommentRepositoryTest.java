package com.smu.healyx.community;

import com.smu.healyx.community.domain.CommunityComment;
import com.smu.healyx.community.domain.CommunityPost;
import com.smu.healyx.community.repository.CommunityCommentRepository;
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
public class CommunityCommentRepositoryTest {

    @Autowired private CommunityCommentRepository communityCommentRepository;
    @Autowired private CommunityPostRepository communityPostRepository;
    @Autowired private UserRepository userRepository;

    private User createUser(String username, String email, String nickname) {
        return userRepository.save(User.builder()
                .username(username).passwordHash("hash")
                .realName("테스트").email(email)
                .nickname(nickname).preferredLanguage("en")
                .build());
    }

    private CommunityPost createPost(User user) {
        return communityPostRepository.save(CommunityPost.builder()
                .user(user).category("자유")
                .title("댓글테스트").content("내용")
                .build());
    }

    @Test
    void 댓글_저장_및_조회() {
        User user = createUser("commentuser1", "comment1@healyx.com", "댓글닉1");
        CommunityPost post = createPost(user);

        communityCommentRepository.save(CommunityComment.builder()
                .post(post).user(user)
                .content("첫 번째 댓글").depth(0)
                .build());

        List<CommunityComment> result = communityCommentRepository
                .findByPost_PostIdAndIsDeletedFalse(post.getPostId());

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getDepth()).isEqualTo(0);
    }

    @Test
    void 대댓글_저장_및_조회() {
        User user = createUser("commentuser2", "comment2@healyx.com", "댓글닉2");
        CommunityPost post = createPost(user);

        CommunityComment parent = communityCommentRepository.save(CommunityComment.builder()
                .post(post).user(user)
                .content("부모 댓글").depth(0)
                .build());

        communityCommentRepository.save(CommunityComment.builder()
                .post(post).user(user)
                .parentComment(parent)
                .content("대댓글").depth(1)
                .build());

        List<CommunityComment> result = communityCommentRepository
                .findByParentComment_CommentIdAndIsDeletedFalse(parent.getCommentId());

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getDepth()).isEqualTo(1);
    }
}
