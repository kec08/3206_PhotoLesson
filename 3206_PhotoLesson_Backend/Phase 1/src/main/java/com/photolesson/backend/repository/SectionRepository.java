package com.photolesson.backend.repository;

import com.photolesson.backend.entity.Section;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SectionRepository extends JpaRepository<Section, Long> {
    List<Section> findByCourseIdOrderBySortOrderAsc(Long courseId);
}
