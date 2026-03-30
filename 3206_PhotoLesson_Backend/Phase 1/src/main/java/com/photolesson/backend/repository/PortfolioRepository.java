package com.photolesson.backend.repository;

import com.photolesson.backend.entity.Portfolio;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PortfolioRepository extends JpaRepository<Portfolio, Long> {
    Page<Portfolio> findByMemberId(Long memberId, Pageable pageable);
}
