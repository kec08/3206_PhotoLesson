package com.photolesson.backend.controller;

import com.photolesson.backend.dto.course.CourseDetailDto;
import com.photolesson.backend.dto.lecture.*;
import com.photolesson.backend.service.LectureService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class LectureController {

    private final LectureService lectureService;

    @GetMapping("/courses/{courseId}/sections")
    public ResponseEntity<List<CourseDetailDto.SectionDto>> getSectionsByCourse(@PathVariable Long courseId) {
        List<CourseDetailDto.SectionDto> sections = lectureService.getSectionsByCourseId(courseId);
        return ResponseEntity.ok(sections);
    }

    @GetMapping("/sections/{sectionId}/lectures")
    public ResponseEntity<List<LectureDto>> getLecturesBySection(@PathVariable Long sectionId) {
        List<LectureDto> lectures = lectureService.getLecturesBySectionId(sectionId);
        return ResponseEntity.ok(lectures);
    }

    @GetMapping("/lectures/{lectureId}")
    public ResponseEntity<LectureDetailDto> getLectureDetail(@PathVariable Long lectureId) {
        LectureDetailDto lecture = lectureService.getLectureDetail(lectureId);
        return ResponseEntity.ok(lecture);
    }

    @PostMapping("/lectures/{lectureId}/watch-history")
    public ResponseEntity<WatchHistoryResponse> saveWatchHistory(
            @PathVariable Long lectureId,
            @RequestBody WatchHistoryRequest request,
            Authentication authentication) {

        Long memberId = (Long) authentication.getPrincipal();
        WatchHistoryResponse response = lectureService.saveWatchHistory(lectureId, memberId, request);
        return ResponseEntity.ok(response);
    }
}
