package com.photolesson.backend.dto.enrollment;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EnrolledCourseDto {
    private Long courseId;
    private String title;
    private String category;
    private String level;
    private String thumbnailUrl;
    private Integer totalLectures;
    private Integer completedLectures;
    private Double progressPercent;
    private LocalDateTime enrolledAt;
}
