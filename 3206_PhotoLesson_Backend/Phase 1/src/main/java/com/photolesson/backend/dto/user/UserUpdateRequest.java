package com.photolesson.backend.dto.user;

import jakarta.validation.constraints.Size;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserUpdateRequest {
    @Size(max = 50, message = "이름은 50자 이내여야 합니다.")
    private String fullName;

    @Size(max = 500, message = "프로필 이미지 URL은 500자 이내여야 합니다.")
    private String profileImageUrl;
}
