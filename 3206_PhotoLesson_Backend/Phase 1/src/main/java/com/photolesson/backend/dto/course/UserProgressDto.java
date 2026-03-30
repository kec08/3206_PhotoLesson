package com.photolesson.backend.dto.course;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserProgressDto {
    private Boolean isEnrolled;
    private Integer completedLectures;
    private Integer totalLectures;
    private Double progressPercent;
}
