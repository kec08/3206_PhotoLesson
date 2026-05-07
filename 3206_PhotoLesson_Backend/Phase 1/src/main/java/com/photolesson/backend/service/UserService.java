package com.photolesson.backend.service;

import com.photolesson.backend.dto.user.UserDto;
import com.photolesson.backend.dto.user.UserUpdateRequest;
import com.photolesson.backend.entity.Member;
import com.photolesson.backend.exception.CustomException;
import com.photolesson.backend.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserService {

    private final MemberRepository memberRepository;

    @Value("${file.upload-dir}")
    private String uploadDir;

    public UserDto getUserById(Long userId) {
        Member member = memberRepository.findById(userId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        return toUserDto(member);
    }

    @Transactional
    public UserDto updateUser(Long userId, UserUpdateRequest request) {
        Member member = memberRepository.findById(userId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        if (request.getFullName() != null) {
            member.setFullName(request.getFullName());
        }
        if (request.getProfileImageUrl() != null) {
            member.setProfileImageUrl(request.getProfileImageUrl());
        }

        member = memberRepository.save(member);
        return toUserDto(member);
    }

    @Transactional
    public UserDto uploadProfileImage(Long userId, MultipartFile file) {
        Member member = memberRepository.findById(userId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        try {
            Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
            Files.createDirectories(uploadPath);

            // 기존 프로필 이미지 삭제
            if (member.getProfileImageUrl() != null && !member.getProfileImageUrl().isEmpty()) {
                String oldFilename = member.getProfileImageUrl().replace("/uploads/", "");
                Path oldFile = uploadPath.resolve(oldFilename);
                Files.deleteIfExists(oldFile);
            }

            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }
            String storedFilename = "profile_" + userId + "_" + UUID.randomUUID().toString() + extension;

            Path filePath = uploadPath.resolve(storedFilename);
            Files.copy(file.getInputStream(), filePath);

            String imageUrl = "/uploads/" + storedFilename;
            member.setProfileImageUrl(imageUrl);
            member = memberRepository.save(member);

            return toUserDto(member);
        } catch (IOException e) {
            throw new RuntimeException("프로필 이미지 업로드에 실패했습니다.", e);
        }
    }

    private UserDto toUserDto(Member member) {
        return UserDto.builder()
                .userId(member.getId())
                .email(member.getEmail())
                .fullName(member.getFullName())
                .profileImageUrl(member.getProfileImageUrl())
                .role(member.getRole())
                .createdAt(member.getCreatedAt())
                .build();
    }
}
