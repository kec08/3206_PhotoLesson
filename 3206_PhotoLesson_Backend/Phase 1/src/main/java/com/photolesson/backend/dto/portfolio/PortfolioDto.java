package com.photolesson.backend.dto.portfolio;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PortfolioDto {
    private Long portfolioId;
    private Long memberId;
    private String portfolioName;
    private String description;
    private Integer imageCount;
    private LocalDateTime createdAt;
}
