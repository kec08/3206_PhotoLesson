package com.photolesson.backend.controller;

import com.photolesson.backend.dto.course.CourseListItemDto;
import com.photolesson.backend.entity.*;
import com.photolesson.backend.exception.CustomException;
import com.photolesson.backend.repository.*;
import lombok.*;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/teacher")
@RequiredArgsConstructor
public class TeacherController {

    private final CourseRepository courseRepository;
    private final MemberRepository memberRepository;
    private final SectionRepository sectionRepository;
    private final LectureRepository lectureRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final LectureProgressRepository lectureProgressRepository;
    private final CommentRepository commentRepository;
    private final PaymentRepository paymentRepository;

    @Value("${file.upload-dir}")
    private String uploadDir;

    // ========== 강의 썸네일 업로드 ==========

    @PostMapping("/courses/{courseId}/thumbnail")
    public ResponseEntity<Map<String, Object>> uploadCourseThumbnail(
            @PathVariable Long courseId,
            @RequestParam("file") MultipartFile file) {

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> CustomException.notFound("강좌를 찾을 수 없습니다."));

        try {
            Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
            Files.createDirectories(uploadPath);

            // 기존 썸네일 삭제
            if (course.getThumbnailUrl() != null && course.getThumbnailUrl().startsWith("/uploads/")) {
                String oldFilename = course.getThumbnailUrl().replace("/uploads/", "");
                Path oldFile = uploadPath.resolve(oldFilename);
                Files.deleteIfExists(oldFile);
            }

            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }
            String storedFilename = "course_" + courseId + "_" + UUID.randomUUID().toString() + extension;

            Path filePath = uploadPath.resolve(storedFilename);
            Files.copy(file.getInputStream(), filePath);

            String imageUrl = "/uploads/" + storedFilename;
            course.setThumbnailUrl(imageUrl);
            courseRepository.save(course);

            return ResponseEntity.ok(Map.of(
                    "courseId", course.getId(),
                    "thumbnailUrl", imageUrl,
                    "message", "썸네일이 업로드되었습니다."
            ));
        } catch (Exception e) {
            throw CustomException.badRequest("썸네일 업로드에 실패했습니다: " + e.getMessage());
        }
    }

    // ========== 강의 CRUD ==========

    @PostMapping("/courses")
    public ResponseEntity<Map<String, Object>> createCourse(
            @RequestBody CourseCreateRequest request,
            Authentication authentication) {

        Long memberId = (Long) authentication.getPrincipal();
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        Course course = Course.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .category(request.getCategory())
                .level(request.getLevel())
                .price(request.getPrice())
                .thumbnailUrl(request.getThumbnailUrl())
                .instructorName(member.getFullName())
                .sections(new ArrayList<>())
                .build();

        if (request.getSections() != null) {
            int sectionOrder = 1;
            for (SectionRequest sectionReq : request.getSections()) {
                Section section = Section.builder()
                        .course(course)
                        .title(sectionReq.getTitle())
                        .sortOrder(sectionOrder++)
                        .lectures(new ArrayList<>())
                        .build();

                if (sectionReq.getLectures() != null) {
                    int lectureOrder = 1;
                    for (LectureRequest lectureReq : sectionReq.getLectures()) {
                        Lecture lecture = Lecture.builder()
                                .section(section)
                                .title(lectureReq.getTitle())
                                .videoUrl(lectureReq.getVideoUrl())
                                .playTime(lectureReq.getPlayTime())
                                .sortOrder(lectureOrder++)
                                .build();
                        section.getLectures().add(lecture);
                    }
                }

                course.getSections().add(section);
            }
        }

        course = courseRepository.save(course);

        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "courseId", course.getId(),
                "title", course.getTitle(),
                "message", "코스가 성공적으로 생성되었습니다."
        ));
    }

    @GetMapping("/courses")
    public ResponseEntity<List<CourseListItemDto>> getMyCourses(Authentication authentication) {
        Long memberId = (Long) authentication.getPrincipal();
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        List<Course> courses = courseRepository.findByInstructorNameOrderByCreatedAtDesc(member.getFullName());

        List<CourseListItemDto> result = courses.stream().map(course -> {
            int sectionCount = course.getSections().size();
            int lectureCount = course.getSections().stream()
                    .mapToInt(s -> s.getLectures().size()).sum();

            return CourseListItemDto.builder()
                    .courseId(course.getId())
                    .title(course.getTitle())
                    .category(course.getCategory())
                    .level(course.getLevel())
                    .instructorName(course.getInstructorName())
                    .thumbnailUrl(course.getThumbnailUrl())
                    .price(course.getPrice())
                    .sectionCount(sectionCount)
                    .lectureCount(lectureCount)
                    .createdAt(course.getCreatedAt())
                    .build();
        }).collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    @PutMapping("/courses/{courseId}")
    public ResponseEntity<Map<String, Object>> updateCourse(
            @PathVariable Long courseId,
            @RequestBody CourseCreateRequest request) {

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> CustomException.notFound("강좌를 찾을 수 없습니다."));

        course.setTitle(request.getTitle());
        course.setDescription(request.getDescription());
        course.setCategory(request.getCategory());
        course.setLevel(request.getLevel());
        course.setPrice(request.getPrice());
        course.setThumbnailUrl(request.getThumbnailUrl());

        course = courseRepository.save(course);

        return ResponseEntity.ok(Map.of(
                "courseId", course.getId(),
                "title", course.getTitle(),
                "message", "강좌가 수정되었습니다."
        ));
    }

    @Transactional
    @DeleteMapping("/courses/{courseId}")
    public ResponseEntity<Void> deleteCourse(@PathVariable Long courseId) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> CustomException.notFound("강좌를 찾을 수 없습니다."));

        // 강의에 속한 모든 레슨의 진도 기록 삭제
        for (Section section : course.getSections()) {
            for (Lecture lecture : section.getLectures()) {
                lectureProgressRepository.deleteAll(
                        lectureProgressRepository.findByLectureId(lecture.getId()));
                commentRepository.deleteAll(
                        commentRepository.findByLectureIdOrderByCreatedAtDesc(lecture.getId()));
            }
        }
        // 수강 등록 삭제
        enrollmentRepository.deleteAll(enrollmentRepository.findByCourseId(courseId));

        courseRepository.delete(course);
        return ResponseEntity.noContent().build();
    }

    // ========== 섹션 CRUD ==========

    @PostMapping("/courses/{courseId}/sections")
    public ResponseEntity<Map<String, Object>> addSection(
            @PathVariable Long courseId,
            @RequestBody SectionRequest request) {

        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> CustomException.notFound("강좌를 찾을 수 없습니다."));

        int nextOrder = course.getSections().size() + 1;

        Section section = Section.builder()
                .course(course)
                .title(request.getTitle())
                .sortOrder(nextOrder)
                .lectures(new ArrayList<>())
                .build();

        section = sectionRepository.save(section);

        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "sectionId", section.getId(),
                "title", section.getTitle(),
                "message", "섹션이 추가되었습니다."
        ));
    }

    @PutMapping("/sections/{sectionId}")
    public ResponseEntity<Map<String, Object>> updateSection(
            @PathVariable Long sectionId,
            @RequestBody SectionRequest request) {

        Section section = sectionRepository.findById(sectionId)
                .orElseThrow(() -> CustomException.notFound("섹션을 찾을 수 없습니다."));

        section.setTitle(request.getTitle());
        sectionRepository.save(section);

        return ResponseEntity.ok(Map.of(
                "sectionId", section.getId(),
                "title", section.getTitle(),
                "message", "섹션이 수정되었습니다."
        ));
    }

    @DeleteMapping("/sections/{sectionId}")
    public ResponseEntity<Void> deleteSection(@PathVariable Long sectionId) {
        Section section = sectionRepository.findById(sectionId)
                .orElseThrow(() -> CustomException.notFound("섹션을 찾을 수 없습니다."));

        sectionRepository.delete(section);
        return ResponseEntity.noContent().build();
    }

    // ========== 레슨 CRUD ==========

    @PostMapping("/sections/{sectionId}/lectures")
    public ResponseEntity<Map<String, Object>> addLecture(
            @PathVariable Long sectionId,
            @RequestBody LectureRequest request) {

        Section section = sectionRepository.findById(sectionId)
                .orElseThrow(() -> CustomException.notFound("섹션을 찾을 수 없습니다."));

        int nextOrder = section.getLectures().size() + 1;

        Lecture lecture = Lecture.builder()
                .section(section)
                .title(request.getTitle())
                .videoUrl(request.getVideoUrl())
                .playTime(request.getPlayTime())
                .sortOrder(nextOrder)
                .build();

        lecture = lectureRepository.save(lecture);

        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "lectureId", lecture.getId(),
                "title", lecture.getTitle(),
                "message", "레슨이 추가되었습니다."
        ));
    }

    @PutMapping("/lectures/{lectureId}")
    public ResponseEntity<Map<String, Object>> updateLecture(
            @PathVariable Long lectureId,
            @RequestBody LectureRequest request) {

        Lecture lecture = lectureRepository.findById(lectureId)
                .orElseThrow(() -> CustomException.notFound("레슨을 찾을 수 없습니다."));

        lecture.setTitle(request.getTitle());
        lecture.setVideoUrl(request.getVideoUrl());
        lecture.setPlayTime(request.getPlayTime());
        lectureRepository.save(lecture);

        return ResponseEntity.ok(Map.of(
                "lectureId", lecture.getId(),
                "title", lecture.getTitle(),
                "message", "레슨이 수정되었습니다."
        ));
    }

    @DeleteMapping("/lectures/{lectureId}")
    public ResponseEntity<Void> deleteLecture(@PathVariable Long lectureId) {
        Lecture lecture = lectureRepository.findById(lectureId)
                .orElseThrow(() -> CustomException.notFound("레슨을 찾을 수 없습니다."));

        lectureRepository.delete(lecture);
        return ResponseEntity.noContent().build();
    }

    // ========== 수강생 현황 대시보드 ==========

    @GetMapping("/courses/{courseId}/dashboard")
    public ResponseEntity<CourseDashboardResponse> getCourseDashboard(@PathVariable Long courseId) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> CustomException.notFound("강좌를 찾을 수 없습니다."));

        List<Enrollment> enrollments = enrollmentRepository.findByCourseId(courseId);
        long totalLectures = lectureRepository.countByCourseId(courseId);

        List<StudentProgressDto> students = new ArrayList<>();
        for (Enrollment enrollment : enrollments) {
            Member student = enrollment.getMember();
            List<LectureProgress> progressList = lectureProgressRepository
                    .findByMemberIdAndCourseId(student.getId(), courseId);
            int completed = progressList.size();
            double percent = totalLectures > 0
                    ? Math.round((double) completed / totalLectures * 10000.0) / 100.0 : 0;

            students.add(StudentProgressDto.builder()
                    .userId(student.getId())
                    .fullName(student.getFullName())
                    .email(student.getEmail())
                    .completedLectures(completed)
                    .totalLectures((int) totalLectures)
                    .progressPercent(percent)
                    .enrolledAt(enrollment.getEnrolledAt())
                    .build());
        }

        return ResponseEntity.ok(CourseDashboardResponse.builder()
                .courseId(course.getId())
                .courseTitle(course.getTitle())
                .totalStudents(enrollments.size())
                .totalLectures((int) totalLectures)
                .students(students)
                .build());
    }

    @GetMapping("/dashboard")
    public ResponseEntity<TeacherDashboardResponse> getTeacherDashboard(Authentication authentication) {
        Long memberId = (Long) authentication.getPrincipal();
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        List<Course> courses = courseRepository.findByInstructorNameOrderByCreatedAtDesc(member.getFullName());

        int totalStudents = 0;
        int totalLectures = 0;
        List<CourseSummaryDto> summaries = new ArrayList<>();

        for (Course course : courses) {
            long studentCount = enrollmentRepository.countByCourseId(course.getId());
            int lectureCount = course.getSections().stream()
                    .mapToInt(s -> s.getLectures().size()).sum();

            totalStudents += (int) studentCount;
            totalLectures += lectureCount;

            summaries.add(CourseSummaryDto.builder()
                    .courseId(course.getId())
                    .title(course.getTitle())
                    .category(course.getCategory())
                    .studentCount((int) studentCount)
                    .lectureCount(lectureCount)
                    .createdAt(course.getCreatedAt())
                    .build());
        }

        return ResponseEntity.ok(TeacherDashboardResponse.builder()
                .totalCourses(courses.size())
                .totalStudents(totalStudents)
                .totalLectures(totalLectures)
                .courses(summaries)
                .build());
    }

    // ========== Request / Response DTOs ==========

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor
    public static class CourseCreateRequest {
        private String title;
        private String description;
        private String category;
        private String level;
        private Integer price;
        private String thumbnailUrl;
        private List<SectionRequest> sections;
    }

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor
    public static class SectionRequest {
        private String title;
        private List<LectureRequest> lectures;
    }

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor
    public static class LectureRequest {
        private String title;
        private String videoUrl;
        private Integer playTime;
    }

    @Getter @Builder @AllArgsConstructor
    public static class CourseDashboardResponse {
        private Long courseId;
        private String courseTitle;
        private int totalStudents;
        private int totalLectures;
        private List<StudentProgressDto> students;
    }

    @Getter @Builder @AllArgsConstructor
    public static class StudentProgressDto {
        private Long userId;
        private String fullName;
        private String email;
        private int completedLectures;
        private int totalLectures;
        private double progressPercent;
        private java.time.LocalDateTime enrolledAt;
    }

    @Getter @Builder @AllArgsConstructor
    public static class TeacherDashboardResponse {
        private int totalCourses;
        private int totalStudents;
        private int totalLectures;
        private List<CourseSummaryDto> courses;
    }

    @Getter @Builder @AllArgsConstructor
    public static class CourseSummaryDto {
        private Long courseId;
        private String title;
        private String category;
        private int studentCount;
        private int lectureCount;
        private long revenue;
        private java.time.LocalDateTime createdAt;
    }

    // === 강사 매출 ===
    @GetMapping("/revenue")
    public ResponseEntity<Map<String, Object>> getRevenue(Authentication authentication) {
        Long memberId = (Long) authentication.getPrincipal();
        Member teacher = memberRepository.findById(memberId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        long totalRevenue = paymentRepository.sumRevenueByInstructor(teacher.getFullName());

        List<Map<String, Object>> courseRevenues = courseRepository.findByInstructorNameOrderByCreatedAtDesc(teacher.getFullName())
                .stream()
                .map(course -> {
                    List<com.photolesson.backend.entity.Payment> payments =
                            paymentRepository.findByCourseIdAndStatus(course.getId(), "SUCCESS");
                    long courseRev = payments.stream().mapToLong(p -> p.getAmount()).sum();
                    return Map.<String, Object>of(
                            "courseId", course.getId(),
                            "title", course.getTitle(),
                            "price", course.getPrice() != null ? course.getPrice() : 0,
                            "revenue", courseRev,
                            "salesCount", payments.size()
                    );
                }).toList();

        return ResponseEntity.ok(Map.of(
                "totalRevenue", totalRevenue,
                "courses", courseRevenues
        ));
    }
}
