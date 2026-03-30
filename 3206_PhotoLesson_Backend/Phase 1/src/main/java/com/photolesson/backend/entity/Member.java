package com.photolesson.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "members")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(length = 100, unique = true, nullable = false)
    private String email;

    @Column(length = 255, nullable = false)
    private String password;

    @Column(name = "full_name", length = 100)
    private String fullName;

    @Column(name = "profile_image_url", length = 500)
    private String profileImageUrl;

    @Column(length = 20)
    @Builder.Default
    private String role = "STUDENT";

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
