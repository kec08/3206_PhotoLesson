package com.photolesson.backend.dto.lecture;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WatchHistoryResponse {
    private Long progressId;
    private Long lectureId;
    private Long memberId;
    private Integer lastPosition;
    private LocalDateTime updatedAt;
}
