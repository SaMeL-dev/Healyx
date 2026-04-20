package com.smu.healyx.community.domain;

import com.smu.healyx.user.domain.User;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "community_likes",
        uniqueConstraints = @UniqueConstraint(columnNames = {"post_id", "user_id"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class CommunityLike {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "like_id")
    private Long likeId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", nullable = false)
    private CommunityPost post;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
    }
}
