package com.photolesson.backend.controller;

import com.photolesson.backend.dto.common.PageResponseDto;
import com.photolesson.backend.dto.portfolio.*;
import com.photolesson.backend.service.PortfolioService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/v1/portfolios")
@RequiredArgsConstructor
public class PortfolioController {

    private final PortfolioService portfolioService;

    @PostMapping
    public ResponseEntity<PortfolioDto> createPortfolio(
            @RequestBody PortfolioCreateRequest request,
            Authentication authentication) {

        Long memberId = (Long) authentication.getPrincipal();
        PortfolioDto response = portfolioService.createPortfolio(memberId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<PageResponseDto<PortfolioDto>> getPortfolios(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication authentication) {

        Long memberId = (Long) authentication.getPrincipal();
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        PageResponseDto<PortfolioDto> response = portfolioService.getPortfolios(memberId, pageable);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{portfolioId}")
    public ResponseEntity<PortfolioDto> getPortfolio(@PathVariable Long portfolioId) {
        PortfolioDto response = portfolioService.getPortfolio(portfolioId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{portfolioId}/images")
    public ResponseEntity<List<PortfolioImageDto>> getPortfolioImages(@PathVariable Long portfolioId) {
        List<PortfolioImageDto> images = portfolioService.getPortfolioImages(portfolioId);
        return ResponseEntity.ok(images);
    }

    @PostMapping("/{portfolioId}/images")
    public ResponseEntity<PortfolioImageDto> uploadImage(
            @PathVariable Long portfolioId,
            @RequestParam("file") MultipartFile file) {

        PortfolioImageDto response = portfolioService.uploadImage(portfolioId, file);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @DeleteMapping("/{portfolioId}/images/{imageId}")
    public ResponseEntity<Void> deleteImage(
            @PathVariable Long portfolioId,
            @PathVariable Long imageId) {

        portfolioService.deleteImage(portfolioId, imageId);
        return ResponseEntity.ok().build();
    }
}
