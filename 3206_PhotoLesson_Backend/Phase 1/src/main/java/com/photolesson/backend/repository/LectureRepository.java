package com.photolesson.backend.repository;

import com.photolesson.backend.entity.Lecture;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface LectureRepository extends JpaRepository<Lecture, Long> {
    List<Lecture> findBySectionIdOrderBySortOrderAsc(Long sectionId);

    @Query("SELECT COUNT(l) FROM Lecture l WHERE l.section.course.id = :courseId")
    long countByCourseId(@Param("courseId") Long courseId);

    @Query("SELECT l FROM Lecture l WHERE l.section.course.id = :courseId")
    List<Lecture> findAllByCourseId(@Param("courseId") Long courseId);
}
