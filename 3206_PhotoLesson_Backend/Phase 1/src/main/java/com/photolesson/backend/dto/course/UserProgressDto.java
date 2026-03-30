package com.photolesson.backend.dto.course;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserProgressDto {
    private Long enrollmentId;
    private Integer completedLectures;
    private Integer totalLectures;
    private Double progressPercent;
}
