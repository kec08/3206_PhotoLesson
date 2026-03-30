package com.photolesson.backend.service;

import com.photolesson.backend.dto.course.CourseDetailDto;
import com.photolesson.backend.dto.lecture.*;
import com.photolesson.backend.entity.*;
import com.photolesson.backend.exception.CustomException;
import com.photolesson.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LectureService {

    private final SectionRepository sectionRepository;
    private final LectureRepository lectureRepository;
    private final LectureProgressRepository lectureProgressRepository;
    private final MemberRepository memberRepository;

    public List<CourseDetailDto.SectionDto> getSectionsByCourseId(Long courseId) {
        List<Section> sections = sectionRepository.findByCourseIdOrderBySortOrderAsc(courseId);

        return sections.stream()
                .map(section -> {
                    List<LectureDto> lectureDtos = section.getLectures().stream()
                            .map(this::toLectureDto)
                            .collect(Collectors.toList());

                    return CourseDetailDto.SectionDto.builder()
                            .sectionId(section.getId())
                            .title(section.getTitle())
                            .sortOrder(section.getSortOrder())
                            .lectures(lectureDtos)
                            .build();
                })
                .collect(Collectors.toList());
    }

    public List<LectureDto> getLecturesBySectionId(Long sectionId) {
        List<Lecture> lectures = lectureRepository.findBySectionIdOrderBySortOrderAsc(sectionId);
        return lectures.stream()
                .map(this::toLectureDto)
                .collect(Collectors.toList());
    }

    public LectureDetailDto getLectureDetail(Long lectureId) {
        Lecture lecture = lectureRepository.findById(lectureId)
                .orElseThrow(() -> CustomException.notFound("강의를 찾을 수 없습니다."));

        return LectureDetailDto.builder()
                .lectureId(lecture.getId())
                .sectionId(lecture.getSection().getId())
                .title(lecture.getTitle())
                .videoUrl(lecture.getVideoUrl())
                .playTime(lecture.getPlayTime())
                .sortOrder(lecture.getSortOrder())
                .sectionTitle(lecture.getSection().getTitle())
                .courseTitle(lecture.getSection().getCourse().getTitle())
                .build();
    }

    @Transactional
    public WatchHistoryResponse saveWatchHistory(Long lectureId, Long memberId, WatchHistoryRequest request) {
        Lecture lecture = lectureRepository.findById(lectureId)
                .orElseThrow(() -> CustomException.notFound("강의를 찾을 수 없습니다."));

        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        LectureProgress progress = lectureProgressRepository
                .findByMemberIdAndLectureId(memberId, lectureId)
                .orElse(LectureProgress.builder()
                        .member(member)
                        .lecture(lecture)
                        .build());

        progress.setLastPosition(request.getLastPosition());
        progress = lectureProgressRepository.save(progress);

        return WatchHistoryResponse.builder()
                .progressId(progress.getId())
                .lectureId(lecture.getId())
                .memberId(member.getId())
                .lastPosition(progress.getLastPosition())
                .updatedAt(progress.getUpdatedAt())
                .build();
    }

    private LectureDto toLectureDto(Lecture lecture) {
        return LectureDto.builder()
                .lectureId(lecture.getId())
                .title(lecture.getTitle())
                .videoUrl(lecture.getVideoUrl())
                .playTime(lecture.getPlayTime())
                .sortOrder(lecture.getSortOrder())
                .build();
    }
}
