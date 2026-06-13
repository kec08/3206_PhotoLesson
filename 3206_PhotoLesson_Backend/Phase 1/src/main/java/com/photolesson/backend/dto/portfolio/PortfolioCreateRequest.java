package com.photolesson.backend.dto.portfolio;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PortfolioCreateRequest {
    @NotBlank(message = "포트폴리오 이름은 필수입니다.")
    @Size(max = 100, message = "포트폴리오 이름은 100자 이내여야 합니다.")
    private String portfolioName;

    @Size(max = 500, message = "설명은 500자 이내여야 합니다.")
    private String description;
}
