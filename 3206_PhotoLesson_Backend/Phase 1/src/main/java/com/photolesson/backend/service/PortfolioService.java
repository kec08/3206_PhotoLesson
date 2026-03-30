package com.photolesson.backend.service;

import com.photolesson.backend.dto.common.PageResponseDto;
import com.photolesson.backend.dto.portfolio.*;
import com.photolesson.backend.entity.*;
import com.photolesson.backend.exception.CustomException;
import com.photolesson.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PortfolioService {

    private final PortfolioRepository portfolioRepository;
    private final PortfolioImageRepository portfolioImageRepository;
    private final MemberRepository memberRepository;

    @Value("${file.upload-dir}")
    private String uploadDir;

    @Transactional
    public PortfolioDto createPortfolio(Long memberId, PortfolioCreateRequest request) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        Portfolio portfolio = Portfolio.builder()
                .member(member)
                .portfolioName(request.getPortfolioName())
                .description(request.getDescription())
                .build();

        portfolio = portfolioRepository.save(portfolio);

        return toPortfolioDto(portfolio);
    }

    public PageResponseDto<PortfolioDto> getPortfolios(Long memberId, Pageable pageable) {
        Page<Portfolio> page = portfolioRepository.findByMemberId(memberId, pageable);

        List<PortfolioDto> content = page.getContent().stream()
                .map(this::toPortfolioDto)
                .collect(Collectors.toList());

        return PageResponseDto.from(page, content);
    }

    public PortfolioDto getPortfolio(Long portfolioId) {
        Portfolio portfolio = portfolioRepository.findById(portfolioId)
                .orElseThrow(() -> CustomException.notFound("포트폴리오를 찾을 수 없습니다."));

        return toPortfolioDto(portfolio);
    }

    public List<PortfolioImageDto> getPortfolioImages(Long portfolioId) {
        if (!portfolioRepository.existsById(portfolioId)) {
            throw CustomException.notFound("포트폴리오를 찾을 수 없습니다.");
        }

        return portfolioImageRepository.findByPortfolioIdOrderByUploadedAtDesc(portfolioId).stream()
                .map(this::toPortfolioImageDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public PortfolioImageDto uploadImage(Long portfolioId, MultipartFile file) {
        Portfolio portfolio = portfolioRepository.findById(portfolioId)
                .orElseThrow(() -> CustomException.notFound("포트폴리오를 찾을 수 없습니다."));

        try {
            Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
            Files.createDirectories(uploadPath);

            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }
            String storedFilename = UUID.randomUUID().toString() + extension;

            Path filePath = uploadPath.resolve(storedFilename);
            Files.copy(file.getInputStream(), filePath);

            String imageUrl = "/uploads/" + storedFilename;

            PortfolioImage image = PortfolioImage.builder()
                    .portfolio(portfolio)
                    .imageUrl(imageUrl)
                    .thumbnailUrl(imageUrl)
                    .build();

            image = portfolioImageRepository.save(image);

            return toPortfolioImageDto(image);
        } catch (IOException e) {
            throw new RuntimeException("파일 업로드에 실패했습니다.", e);
        }
    }

    @Transactional
    public void deleteImage(Long portfolioId, Long imageId) {
        PortfolioImage image = portfolioImageRepository.findById(imageId)
                .orElseThrow(() -> CustomException.notFound("이미지를 찾을 수 없습니다."));

        if (!image.getPortfolio().getId().equals(portfolioId)) {
            throw CustomException.badRequest("해당 포트폴리오의 이미지가 아닙니다.");
        }

        portfolioImageRepository.delete(image);
    }

    private PortfolioDto toPortfolioDto(Portfolio portfolio) {
        int imageCount = (int) portfolioImageRepository.countByPortfolioId(portfolio.getId());

        return PortfolioDto.builder()
                .portfolioId(portfolio.getId())
                .memberId(portfolio.getMember().getId())
                .portfolioName(portfolio.getPortfolioName())
                .description(portfolio.getDescription())
                .imageCount(imageCount)
                .createdAt(portfolio.getCreatedAt())
                .build();
    }

    private PortfolioImageDto toPortfolioImageDto(PortfolioImage image) {
        return PortfolioImageDto.builder()
                .imageId(image.getId())
                .portfolioId(image.getPortfolio().getId())
                .imageUrl(image.getImageUrl())
                .thumbnailUrl(image.getThumbnailUrl())
                .uploadedAt(image.getUploadedAt())
                .build();
    }
}
