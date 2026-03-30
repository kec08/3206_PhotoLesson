package com.photolesson.backend.repository;

import com.photolesson.backend.entity.PortfolioImage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PortfolioImageRepository extends JpaRepository<PortfolioImage, Long> {
    List<PortfolioImage> findByPortfolioIdOrderByUploadedAtDesc(Long portfolioId);
    long countByPortfolioId(Long portfolioId);
}
