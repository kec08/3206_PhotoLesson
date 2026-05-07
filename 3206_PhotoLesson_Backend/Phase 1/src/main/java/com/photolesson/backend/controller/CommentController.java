package com.photolesson.backend.controller;

import com.photolesson.backend.dto.comment.CommentCreateRequest;
import com.photolesson.backend.dto.comment.CommentDto;
import com.photolesson.backend.service.CommentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    @PostMapping("/lectures/{lectureId}/comments")
    public ResponseEntity<CommentDto> createComment(
            @PathVariable Long lectureId,
            @Valid @RequestBody CommentCreateRequest request,
            Authentication authentication) {
        Long memberId = (Long) authentication.getPrincipal();
        CommentDto comment = commentService.createComment(memberId, lectureId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(comment);
    }

    @GetMapping("/lectures/{lectureId}/comments")
    public ResponseEntity<List<CommentDto>> getComments(@PathVariable Long lectureId) {
        List<CommentDto> comments = commentService.getCommentsByLecture(lectureId);
        return ResponseEntity.ok(comments);
    }

    @DeleteMapping("/comments/{commentId}")
    public ResponseEntity<Void> deleteComment(
            @PathVariable Long commentId,
            Authentication authentication) {
        Long memberId = (Long) authentication.getPrincipal();
        String role = extractRole(authentication);
        commentService.deleteComment(memberId, commentId, role);
        return ResponseEntity.noContent().build();
    }

    private String extractRole(Authentication authentication) {
        return authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .filter(a -> a.startsWith("ROLE_"))
                .map(a -> a.substring(5)) // Remove "ROLE_" prefix
                .findFirst()
                .orElse("STUDENT");
    }
}
