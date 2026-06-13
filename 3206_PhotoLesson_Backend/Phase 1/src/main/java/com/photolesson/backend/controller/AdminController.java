package com.photolesson.backend.controller;

import com.photolesson.backend.dto.user.UserDto;
import com.photolesson.backend.entity.*;
import com.photolesson.backend.exception.CustomException;
import com.photolesson.backend.repository.*;
import com.photolesson.backend.service.PaymentService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final MemberRepository memberRepository;
    private final CourseRepository courseRepository;
    private final PaymentRepository paymentRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final LectureRepository lectureRepository;
    private final LectureProgressRepository lectureProgressRepository;
    private final PaymentService paymentService;

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

    // ========== 통계 API ==========

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStats() {
        LocalDateTime todayStart = LocalDate.now().atStartOfDay();

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("totalUsers", memberRepository.count());
        stats.put("totalCourses", courseRepository.count());
        stats.put("totalPayments", paymentRepository.countByStatus("SUCCESS"));
        stats.put("totalRevenue", paymentRepository.sumTotalRevenue());
        stats.put("todayRevenue", paymentRepository.sumRevenueAfter(todayStart));
        stats.put("todayPayments", paymentRepository.countByCreatedAtAfter(todayStart));

        return ResponseEntity.ok(stats);
    }

    @GetMapping("/payments")
    public ResponseEntity<Page<?>> getPayments(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(paymentService.getAllPayments(PageRequest.of(page, size)));
    }

    @PostMapping("/payments/{paymentId}/refund")
    public ResponseEntity<Void> refundPayment(@PathVariable Long paymentId) {
        paymentService.refundPayment(paymentId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/courses/dashboard")
    public ResponseEntity<List<Map<String, Object>>> getCoursesDashboard() {
        List<Course> courses = courseRepository.findAll();
        List<Map<String, Object>> result = new ArrayList<>();

        for (Course course : courses) {
            long studentCount = enrollmentRepository.countByCourseId(course.getId());
            long lectureCount = lectureRepository.countByCourseId(course.getId());
            List<Payment> payments = paymentRepository.findByCourseIdAndStatus(course.getId(), "SUCCESS");
            long revenue = payments.stream().mapToLong(Payment::getAmount).sum();

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("courseId", course.getId());
            item.put("courseTitle", course.getTitle());
            item.put("instructorName", course.getInstructorName());
            item.put("totalStudents", studentCount);
            item.put("totalLectures", lectureCount);
            item.put("revenue", revenue);
            item.put("salesCount", payments.size());
            result.add(item);
        }

        return ResponseEntity.ok(result);
    }

    @GetMapping("/courses/{courseId}/stats")
    public ResponseEntity<Map<String, Object>> getCourseStats(@PathVariable Long courseId) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> CustomException.notFound("강좌를 찾을 수 없습니다."));

        List<Enrollment> enrollments = enrollmentRepository.findByCourseId(courseId);
        long totalLectures = lectureRepository.countByCourseId(courseId);
        List<Payment> payments = paymentRepository.findByCourseIdAndStatus(courseId, "SUCCESS");
        long revenue = payments.stream().mapToLong(Payment::getAmount).sum();

        List<Map<String, Object>> students = new ArrayList<>();
        double totalProgress = 0;

        for (Enrollment enrollment : enrollments) {
            Member student = enrollment.getMember();
            List<LectureProgress> progress = lectureProgressRepository
                    .findByMemberIdAndCourseId(student.getId(), courseId);
            double progressPercent = totalLectures > 0
                    ? Math.round((double) progress.size() / totalLectures * 100.0 * 100.0) / 100.0
                    : 0;
            totalProgress += progressPercent;

            Map<String, Object> s = new LinkedHashMap<>();
            s.put("userId", student.getId());
            s.put("fullName", student.getFullName());
            s.put("email", student.getEmail());
            s.put("completedLectures", progress.size());
            s.put("totalLectures", totalLectures);
            s.put("progressPercent", progressPercent);
            s.put("enrolledAt", enrollment.getEnrolledAt());
            students.add(s);
        }

        double avgProgress = enrollments.isEmpty() ? 0
                : Math.round(totalProgress / enrollments.size() * 100.0) / 100.0;

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("courseId", course.getId());
        result.put("courseTitle", course.getTitle());
        result.put("totalStudents", enrollments.size());
        result.put("avgProgress", avgProgress);
        result.put("revenue", revenue);
        result.put("salesCount", payments.size());
        result.put("students", students);

        return ResponseEntity.ok(result);
    }

    @GetMapping("/report/monthly")
    public ResponseEntity<List<Map<String, Object>>> getMonthlyReport() {
        List<Payment> allSuccess = paymentRepository.findByCourseIdAndStatus(null, "SUCCESS");
        // 전체 SUCCESS 결제를 월별로 그룹핑
        List<Payment> successPayments = paymentRepository.findAll().stream()
                .filter(p -> "SUCCESS".equals(p.getStatus()))
                .toList();

        Map<String, List<Payment>> byMonth = successPayments.stream()
                .collect(Collectors.groupingBy(p ->
                        p.getCreatedAt().getYear() + "-" +
                        String.format("%02d", p.getCreatedAt().getMonthValue())));

        List<Map<String, Object>> result = byMonth.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(entry -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("month", entry.getKey());
                    m.put("totalRevenue", entry.getValue().stream().mapToLong(Payment::getAmount).sum());
                    m.put("paymentCount", entry.getValue().size());
                    return m;
                })
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
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
