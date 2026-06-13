package com.photolesson.backend.dto.enrollment;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class EnrollmentRequest {
    @NotNull(message = "강좌 ID는 필수입니다.")
    private Long courseId;
}
