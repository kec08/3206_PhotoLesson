package com.photolesson.backend.repository;

import com.photolesson.backend.entity.Enrollment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {
    @EntityGraph(attributePaths = {"member", "course"})
    List<Enrollment> findByMemberId(Long memberId);

    Optional<Enrollment> findByMemberIdAndCourseId(Long memberId, Long courseId);
    boolean existsByMemberIdAndCourseId(Long memberId, Long courseId);

    @EntityGraph(attributePaths = {"member"})
    List<Enrollment> findByCourseId(Long courseId);

    long countByCourseId(Long courseId);
}
