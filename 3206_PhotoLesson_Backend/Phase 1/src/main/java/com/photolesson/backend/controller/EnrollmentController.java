package com.photolesson.backend.controller;

import com.photolesson.backend.dto.enrollment.*;
import com.photolesson.backend.service.EnrollmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class EnrollmentController {

    private final EnrollmentService enrollmentService;

    @PostMapping("/enrollments")
    public ResponseEntity<EnrollmentResponse> enroll(
            @RequestBody EnrollmentRequest request,
            Authentication authentication) {

        Long memberId = (Long) authentication.getPrincipal();
        EnrollmentResponse response = enrollmentService.enroll(memberId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/users/{userId}/enrollments")
    public ResponseEntity<List<EnrollmentResponse>> getUserEnrollments(@PathVariable Long userId) {
        List<EnrollmentResponse> responses = enrollmentService.getUserEnrollments(userId);
        return ResponseEntity.ok(responses);
    }

    @GetMapping("/users/{userId}/progress")
    public ResponseEntity<ProgressResponseDto> getUserProgress(@PathVariable Long userId) {
        ProgressResponseDto response = enrollmentService.getUserProgress(userId);
        return ResponseEntity.ok(response);
    }
}
