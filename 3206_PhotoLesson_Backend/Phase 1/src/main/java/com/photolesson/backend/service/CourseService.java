package com.photolesson.backend.service;

import com.photolesson.backend.dto.common.PageResponseDto;
import com.photolesson.backend.dto.course.CourseDetailDto;
import com.photolesson.backend.dto.course.CourseListItemDto;
import com.photolesson.backend.dto.course.UserProgressDto;
import com.photolesson.backend.dto.lecture.LectureDto;
import com.photolesson.backend.entity.*;
import com.photolesson.backend.exception.CustomException;
import com.photolesson.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CourseService {

    private final CourseRepository courseRepository;
    private final SectionRepository sectionRepository;
    private final LectureRepository lectureRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final LectureProgressRepository lectureProgressRepository;

    public PageResponseDto<CourseListItemDto> getCourses(String category, Pageable pageable) {
        Page<Course> coursePage;
        if (category != null && !category.isEmpty()) {
            coursePage = courseRepository.findByCategory(category, pageable);
        } else {
            coursePage = courseRepository.findAll(pageable);
        }

        List<CourseListItemDto> content = coursePage.getContent().stream()
                .map(this::toCourseListItem)
                .collect(Collectors.toList());

        return PageResponseDto.from(coursePage, content);
    }

    public PageResponseDto<CourseListItemDto> searchCourses(String keyword, Pageable pageable) {
        Page<Course> coursePage = courseRepository.searchByKeyword(keyword, pageable);

        List<CourseListItemDto> content = coursePage.getContent().stream()
                .map(this::toCourseListItem)
                .collect(Collectors.toList());

        return PageResponseDto.from(coursePage, content);
    }

    public CourseDetailDto getCourseDetail(Long courseId, Long memberId) {
        Course course = courseRepository.findById(courseId)
                .orElseThrow(() -> CustomException.notFound("강좌를 찾을 수 없습니다."));

        List<Section> sections = sectionRepository.findByCourseIdOrderBySortOrderAsc(courseId);

        List<CourseDetailDto.SectionDto> sectionDtos = sections.stream()
                .map(section -> {
                    List<LectureDto> lectureDtos = section.getLectures().stream()
                            .map(lecture -> LectureDto.builder()
                                    .lectureId(lecture.getId())
                                    .title(lecture.getTitle())
                                    .videoUrl(lecture.getVideoUrl())
                                    .playTime(lecture.getPlayTime())
                                    .sortOrder(lecture.getSortOrder())
                                    .build())
                            .collect(Collectors.toList());

                    return CourseDetailDto.SectionDto.builder()
                            .sectionId(section.getId())
                            .title(section.getTitle())
                            .sortOrder(section.getSortOrder())
                            .lectures(lectureDtos)
                            .build();
                })
                .collect(Collectors.toList());

        UserProgressDto userProgress = null;
        if (memberId != null) {
            Optional<Enrollment> enrollmentOpt = enrollmentRepository.findByMemberIdAndCourseId(memberId, courseId);
            if (enrollmentOpt.isPresent()) {
                long totalLectures = lectureRepository.countByCourseId(courseId);
                List<LectureProgress> progressList = lectureProgressRepository.findByMemberIdAndCourseId(memberId, courseId);
                int completedLectures = progressList.size();
                double progressPercent = totalLectures > 0 ? (double) completedLectures / totalLectures * 100 : 0;

                userProgress = UserProgressDto.builder()
                        .enrollmentId(enrollmentOpt.get().getId())
                        .completedLectures(completedLectures)
                        .totalLectures((int) totalLectures)
                        .progressPercent(Math.round(progressPercent * 100.0) / 100.0)
                        .build();
            }
        }

        return CourseDetailDto.builder()
                .courseId(course.getId())
                .title(course.getTitle())
                .description(course.getDescription())
                .category(course.getCategory())
                .level(course.getLevel())
                .instructorName(course.getInstructorName())
                .thumbnailUrl(course.getThumbnailUrl())
                .price(course.getPrice())
                .createdAt(course.getCreatedAt())
                .sections(sectionDtos)
                .userProgress(userProgress)
                .build();
    }

    private CourseListItemDto toCourseListItem(Course course) {
        int sectionCount = course.getSections().size();
        int lectureCount = course.getSections().stream()
                .mapToInt(s -> s.getLectures().size())
                .sum();

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
    }
}
