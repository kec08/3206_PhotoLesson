package com.photolesson.backend.dto.lecture;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LectureDto {
    private Long lectureId;
    private String title;
    private String videoUrl;
    private Integer playTime;
    private Integer sortOrder;
}
