package com.photolesson.backend.repository;

import com.photolesson.backend.entity.Payment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface PaymentRepository extends JpaRepository<Payment, Long> {
    Optional<Payment> findByOrderId(String orderId);
    List<Payment> findByMemberIdOrderByCreatedAtDesc(Long memberId);
    Page<Payment> findAllByOrderByCreatedAtDesc(Pageable pageable);
    boolean existsByMemberIdAndCourseIdAndStatus(Long memberId, Long courseId, String status);

    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM Payment p WHERE p.status = 'SUCCESS' AND p.createdAt > :after")
    long sumRevenueAfter(LocalDateTime after);

    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM Payment p WHERE p.status = 'SUCCESS'")
    long sumTotalRevenue();

    long countByStatus(String status);
    long countByCreatedAtAfter(LocalDateTime after);

    // 강사별 매출
    @Query("SELECT COALESCE(SUM(p.amount), 0) FROM Payment p WHERE p.status = 'SUCCESS' AND p.course.instructorName = :instructorName")
    long sumRevenueByInstructor(String instructorName);

    List<Payment> findByCourseIdAndStatus(Long courseId, String status);
}
