package com.photolesson.backend.dto.enrollment;

import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProgressResponseDto {
    private Long userId;
    private List<EnrolledCourseDto> progress;
    private Integer totalCompletedLectures;
    private Integer totalEnrolledCourses;
    private Double totalProgressPercent;
}
