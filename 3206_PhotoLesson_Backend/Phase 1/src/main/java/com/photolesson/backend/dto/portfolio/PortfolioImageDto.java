package com.photolesson.backend.dto.portfolio;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PortfolioImageDto {
    private Long imageId;
    private Long portfolioId;
    private String imageUrl;
    private String thumbnailUrl;
    private LocalDateTime uploadedAt;
}
