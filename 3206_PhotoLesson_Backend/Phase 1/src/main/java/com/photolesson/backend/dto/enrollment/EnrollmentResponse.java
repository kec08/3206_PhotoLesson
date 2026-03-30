package com.photolesson.backend.dto.enrollment;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EnrollmentResponse {
    private Long enrollmentId;
    private Long memberId;
    private Long courseId;
    private LocalDateTime enrolledAt;
    private Boolean isCompleted;
}
