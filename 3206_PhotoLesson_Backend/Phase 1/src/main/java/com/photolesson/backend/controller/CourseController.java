package com.photolesson.backend.controller;

import com.photolesson.backend.dto.common.PageResponseDto;
import com.photolesson.backend.dto.course.CourseDetailDto;
import com.photolesson.backend.dto.course.CourseListItemDto;
import com.photolesson.backend.service.CourseService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/courses")
@RequiredArgsConstructor
public class CourseController {

    private final CourseService courseService;

    @GetMapping
    public ResponseEntity<PageResponseDto<CourseListItemDto>> getCourses(
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt,desc") String sort) {

        String[] sortParts = sort.split(",");
        String sortField = sortParts[0];
        Sort.Direction direction = sortParts.length > 1 && sortParts[1].equalsIgnoreCase("asc")
                ? Sort.Direction.ASC : Sort.Direction.DESC;

        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortField));
        PageResponseDto<CourseListItemDto> response = courseService.getCourses(category, pageable);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{courseId}")
    public ResponseEntity<CourseDetailDto> getCourseDetail(
            @PathVariable Long courseId,
            Authentication authentication) {

        Long memberId = null;
        if (authentication != null && authentication.getPrincipal() instanceof Long) {
            memberId = (Long) authentication.getPrincipal();
        }

        CourseDetailDto response = courseService.getCourseDetail(courseId, memberId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/search")
    public ResponseEntity<PageResponseDto<CourseListItemDto>> searchCourses(
            @RequestParam String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        PageResponseDto<CourseListItemDto> response = courseService.searchCourses(keyword, pageable);
        return ResponseEntity.ok(response);
    }
}
