package com.photolesson.backend.repository;

import com.photolesson.backend.entity.Enrollment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {
    List<Enrollment> findByMemberId(Long memberId);
    Optional<Enrollment> findByMemberIdAndCourseId(Long memberId, Long courseId);
    boolean existsByMemberIdAndCourseId(Long memberId, Long courseId);
}
