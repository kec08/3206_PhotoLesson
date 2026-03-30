package com.photolesson.backend.dto.user;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDto {
    private Long userId;
    private String email;
    private String fullName;
    private String profileImageUrl;
    private String role;
    private LocalDateTime createdAt;
}
