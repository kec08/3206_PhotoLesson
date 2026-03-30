package com.photolesson.backend.dto.course;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CourseListItemDto {
    private Long courseId;
    private String title;
    private String category;
    private String level;
    private String instructorName;
    private String thumbnailUrl;
    private Integer price;
    private Integer sectionCount;
    private Integer lectureCount;
    private LocalDateTime createdAt;
}
