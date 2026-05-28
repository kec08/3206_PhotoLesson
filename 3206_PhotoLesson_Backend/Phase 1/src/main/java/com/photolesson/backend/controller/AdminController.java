package com.photolesson.backend.controller;

import com.photolesson.backend.dto.payment.PaymentDto;
import com.photolesson.backend.dto.user.UserDto;
import com.photolesson.backend.entity.Member;
import com.photolesson.backend.exception.CustomException;
import com.photolesson.backend.repository.*;
import com.photolesson.backend.service.PaymentService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final MemberRepository memberRepository;
    private final LectureProgressRepository lectureProgressRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final PortfolioImageRepository portfolioImageRepository;
    private final PortfolioRepository portfolioRepository;
    private final CommentRepository commentRepository;
    private final PaymentRepository paymentRepository;
    private final PaymentService paymentService;
    private final CourseRepository courseRepository;

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

    @Transactional
    @DeleteMapping("/users/{userId}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long userId) {
        Member member = memberRepository.findById(userId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        // 관련 데이터 순서대로 삭제
        lectureProgressRepository.deleteAll(lectureProgressRepository.findByMemberId(userId));
        commentRepository.deleteAll(commentRepository.findByMemberId(userId));
        portfolioRepository.findAllByMemberId(userId).forEach(p -> {
            portfolioImageRepository.deleteAll(portfolioImageRepository.findByPortfolioId(p.getId()));
        });
        portfolioRepository.deleteAll(portfolioRepository.findAllByMemberId(userId));
        enrollmentRepository.deleteAll(enrollmentRepository.findByMemberId(userId));
        memberRepository.delete(member);

        return ResponseEntity.noContent().build();
    }

    // === 결제 관리 ===
    @GetMapping("/payments")
    public ResponseEntity<Page<PaymentDto>> getPayments(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(paymentService.getAllPayments(PageRequest.of(page, size)));
    }

    @PostMapping("/payments/{paymentId}/refund")
    public ResponseEntity<Void> refundPayment(@PathVariable Long paymentId) {
        paymentService.refundPayment(paymentId);
        return ResponseEntity.noContent().build();
    }

    // === 통계 ===
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStats() {
        java.time.LocalDateTime today = java.time.LocalDate.now().atStartOfDay();
        Map<String, Object> stats = Map.of(
                "totalUsers", memberRepository.count(),
                "totalCourses", courseRepository.count(),
                "totalPayments", paymentRepository.countByStatus("SUCCESS"),
                "totalRevenue", paymentRepository.sumTotalRevenue(),
                "todayRevenue", paymentRepository.sumRevenueAfter(today),
                "todayPayments", paymentRepository.countByCreatedAtAfter(today)
        );
        return ResponseEntity.ok(stats);
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
