package com.photolesson.backend.dto.course;

import com.photolesson.backend.dto.lecture.LectureDto;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CourseDetailDto {
    private Long courseId;
    private String title;
    private String description;
    private String category;
    private String level;
    private String instructorName;
    private String thumbnailUrl;
    private Integer price;
    private LocalDateTime createdAt;
    private List<SectionDto> sections;
    private UserProgressDto userProgress;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class SectionDto {
        private Long sectionId;
        private String title;
        private Integer sortOrder;
        private List<LectureDto> lectures;
    }
}
