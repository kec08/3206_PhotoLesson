package com.photolesson.backend.service;

import com.photolesson.backend.dto.enrollment.*;
import com.photolesson.backend.entity.*;
import com.photolesson.backend.exception.CustomException;
import com.photolesson.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class EnrollmentService {

    private final EnrollmentRepository enrollmentRepository;
    private final MemberRepository memberRepository;
    private final CourseRepository courseRepository;
    private final LectureRepository lectureRepository;
    private final LectureProgressRepository lectureProgressRepository;

    @Transactional
    public EnrollmentResponse enroll(Long memberId, EnrollmentRequest request) {
        if (enrollmentRepository.existsByMemberIdAndCourseId(memberId, request.getCourseId())) {
            throw CustomException.conflict("이미 수강 중인 강좌입니다.");
        }

        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        Course course = courseRepository.findById(request.getCourseId())
                .orElseThrow(() -> CustomException.notFound("강좌를 찾을 수 없습니다."));

        Enrollment enrollment = Enrollment.builder()
                .member(member)
                .course(course)
                .build();

        enrollment = enrollmentRepository.save(enrollment);

        return EnrollmentResponse.builder()
                .enrollmentId(enrollment.getId())
                .memberId(member.getId())
                .courseId(course.getId())
                .enrolledAt(enrollment.getEnrolledAt())
                .isCompleted(enrollment.getIsCompleted())
                .build();
    }

    public List<EnrollmentResponse> getUserEnrollments(Long userId) {
        List<Enrollment> enrollments = enrollmentRepository.findByMemberId(userId);

        List<EnrollmentResponse> responses = new ArrayList<>();
        for (Enrollment enrollment : enrollments) {
            responses.add(EnrollmentResponse.builder()
                    .enrollmentId(enrollment.getId())
                    .memberId(enrollment.getMember().getId())
                    .courseId(enrollment.getCourse().getId())
                    .enrolledAt(enrollment.getEnrolledAt())
                    .isCompleted(enrollment.getIsCompleted())
                    .build());
        }
        return responses;
    }

    public ProgressResponseDto getUserProgress(Long userId) {
        List<Enrollment> enrollments = enrollmentRepository.findByMemberId(userId);

        List<EnrolledCourseDto> progress = new ArrayList<>();
        int totalCompletedLectures = 0;
        int totalLecturesAll = 0;

        for (Enrollment enrollment : enrollments) {
            Course course = enrollment.getCourse();
            long totalLectures = lectureRepository.countByCourseId(course.getId());
            List<LectureProgress> progressList = lectureProgressRepository
                    .findByMemberIdAndCourseId(userId, course.getId());
            int completedLectures = progressList.size();

            double progressPercent = totalLectures > 0
                    ? Math.round((double) completedLectures / totalLectures * 10000.0) / 100.0
                    : 0;

            progress.add(EnrolledCourseDto.builder()
                    .courseId(course.getId())
                    .title(course.getTitle())
                    .category(course.getCategory())
                    .level(course.getLevel())
                    .thumbnailUrl(course.getThumbnailUrl())
                    .totalLectures((int) totalLectures)
                    .completedLectures(completedLectures)
                    .progressPercent(progressPercent)
                    .enrolledAt(enrollment.getEnrolledAt())
                    .build());

            totalCompletedLectures += completedLectures;
            totalLecturesAll += (int) totalLectures;
        }

        double totalProgressPercent = totalLecturesAll > 0
                ? Math.round((double) totalCompletedLectures / totalLecturesAll * 10000.0) / 100.0
                : 0;

        return ProgressResponseDto.builder()
                .userId(userId)
                .progress(progress)
                .totalCompletedLectures(totalCompletedLectures)
                .totalEnrolledCourses(enrollments.size())
                .totalProgressPercent(totalProgressPercent)
                .build();
    }
}
