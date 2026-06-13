package com.photolesson.backend.repository;

import com.photolesson.backend.entity.Course;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface CourseRepository extends JpaRepository<Course, Long> {

    Page<Course> findByCategory(String category, Pageable pageable);

    @Query("SELECT c FROM Course c WHERE LOWER(c.title) LIKE LOWER(CONCAT('%', :keyword, '%')) " +
           "OR LOWER(c.description) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    Page<Course> searchByKeyword(@Param("keyword") String keyword, Pageable pageable);

    @EntityGraph(attributePaths = {"sections"})
    List<Course> findByInstructorNameOrderByCreatedAtDesc(String instructorName);

    @Query("SELECT DISTINCT c FROM Course c LEFT JOIN FETCH c.sections s LEFT JOIN FETCH s.lectures WHERE c.id = :id")
    Optional<Course> findByIdWithSections(@Param("id") Long id);
}
