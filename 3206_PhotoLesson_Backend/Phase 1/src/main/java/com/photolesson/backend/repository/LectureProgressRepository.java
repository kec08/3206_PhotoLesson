package com.photolesson.backend.repository;

import com.photolesson.backend.entity.LectureProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface LectureProgressRepository extends JpaRepository<LectureProgress, Long> {
    Optional<LectureProgress> findByMemberIdAndLectureId(Long memberId, Long lectureId);

    @Query("SELECT lp FROM LectureProgress lp WHERE lp.member.id = :memberId AND lp.lecture.section.course.id = :courseId")
    List<LectureProgress> findByMemberIdAndCourseId(@Param("memberId") Long memberId, @Param("courseId") Long courseId);

    @Query("SELECT COUNT(lp) FROM LectureProgress lp WHERE lp.member.id = :memberId")
    long countByMemberId(@Param("memberId") Long memberId);
}
