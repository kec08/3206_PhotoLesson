package com.photolesson.backend.dto.portfolio;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PortfolioCreateRequest {
    private String portfolioName;
    private String description;
}
