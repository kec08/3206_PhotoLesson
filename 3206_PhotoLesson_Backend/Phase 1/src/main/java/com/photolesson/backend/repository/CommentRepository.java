package com.photolesson.backend.repository;

import com.photolesson.backend.entity.Comment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CommentRepository extends JpaRepository<Comment, Long> {
    List<Comment> findByLectureIdOrderByCreatedAtDesc(Long lectureId);
    List<Comment> findByMemberId(Long memberId);
}
