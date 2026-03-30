package com.photolesson.backend.dto.lecture;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LectureDetailDto {
    private Long lectureId;
    private Long sectionId;
    private String title;
    private String videoUrl;
    private Integer playTime;
    private Integer sortOrder;
    private String sectionTitle;
    private String courseTitle;
}
