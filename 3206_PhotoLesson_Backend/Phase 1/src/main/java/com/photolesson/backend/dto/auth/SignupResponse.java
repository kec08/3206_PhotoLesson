package com.photolesson.backend.dto.auth;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SignupResponse {
    private Long userId;
    private String email;
    private String fullName;
    private LocalDateTime createdAt;
}
