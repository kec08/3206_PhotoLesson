package com.photolesson.backend.dto.lecture;

import jakarta.validation.constraints.Min;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class WatchHistoryRequest {
    @Min(value = 0, message = "재생 위치는 0 이상이어야 합니다.")
    private Integer lastPosition;
}
