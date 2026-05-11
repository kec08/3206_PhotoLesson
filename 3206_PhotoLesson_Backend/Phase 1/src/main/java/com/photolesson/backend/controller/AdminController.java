package com.photolesson.backend.controller;

import com.photolesson.backend.dto.user.UserDto;
import com.photolesson.backend.entity.Member;
import com.photolesson.backend.exception.CustomException;
import com.photolesson.backend.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final MemberRepository memberRepository;

    @GetMapping("/users")
    public ResponseEntity<List<UserDto>> getAllUsers() {
        List<UserDto> users = memberRepository.findAll().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(users);
    }

    @PatchMapping("/users/{userId}/role")
    public ResponseEntity<UserDto> changeUserRole(
            @PathVariable Long userId,
            @RequestBody Map<String, String> body) {

        String newRole = body.get("role");
        if (newRole == null || newRole.isBlank()) {
            throw CustomException.badRequest("역할(role)은 필수입니다.");
        }

        // Validate allowed roles
        if (!List.of("STUDENT", "TEACHER", "ADMIN").contains(newRole.toUpperCase())) {
            throw CustomException.badRequest("유효하지 않은 역할입니다. (STUDENT, TEACHER, ADMIN)");
        }

        Member member = memberRepository.findById(userId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        member.setRole(newRole.toUpperCase());
        member = memberRepository.save(member);

        return ResponseEntity.ok(toDto(member));
    }

    @DeleteMapping("/users/{userId}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long userId) {
        Member member = memberRepository.findById(userId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));
        memberRepository.delete(member);
        return ResponseEntity.noContent().build();
    }

    private UserDto toDto(Member member) {
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
