package com.photolesson.backend.scheduler;

import com.photolesson.backend.entity.Enrollment;
import com.photolesson.backend.entity.Payment;
import com.photolesson.backend.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class ScheduledTasks {

    private final PaymentRepository paymentRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final MemberRepository memberRepository;
    private final CourseRepository courseRepository;

    /**
     * 만료 결제 정리 — 매시간 실행
     * PENDING 상태로 1시간 이상 경과한 결제를 FAILED로 변경
     */
    @Scheduled(cron = "0 0 * * * *", zone = "Asia/Seoul")
    @Transactional
    public void cleanupExpiredPayments() {
        LocalDateTime cutoff = LocalDateTime.now().minusHours(1);
        List<Payment> expiredPayments = paymentRepository.findByStatusAndCreatedAtBefore("PENDING", cutoff);

        if (expiredPayments.isEmpty()) {
            return;
        }

        for (Payment payment : expiredPayments) {
            payment.setStatus("FAILED");
            payment.setFailReason("결제 타임아웃 (1시간 초과)");
        }
        paymentRepository.saveAll(expiredPayments);
        log.info("[스케줄러] 만료 결제 정리: {}건 PENDING → FAILED", expiredPayments.size());
    }

    /**
     * 일일 통계 로깅 — 매일 03:00 실행
     */
    @Scheduled(cron = "0 0 3 * * *", zone = "Asia/Seoul")
    public void logDailyStats() {
        LocalDateTime todayStart = LocalDate.now().atStartOfDay();

        long totalRevenue = paymentRepository.sumTotalRevenue();
        long todayRevenue = paymentRepository.sumRevenueAfter(todayStart);
        long successCount = paymentRepository.countByStatus("SUCCESS");
        long failedCount = paymentRepository.countByStatus("FAILED");
        long pendingCount = paymentRepository.countByStatus("PENDING");
        long totalUsers = memberRepository.count();
        long totalCourses = courseRepository.count();
        long totalEnrollments = enrollmentRepository.count();

        log.info("[일일통계] 총매출={}원, 오늘매출={}원, 결제(성공={}/실패={}/대기={}), 유저={}명, 강좌={}개, 수강={}건",
                totalRevenue, todayRevenue,
                successCount, failedCount, pendingCount,
                totalUsers, totalCourses, totalEnrollments);
    }

    /**
     * 수강 정합성 체크 — 매일 04:00 실행
     * SUCCESS 결제인데 수강등록이 누락된 건을 자동 복구
     */
    @Scheduled(cron = "0 0 4 * * *", zone = "Asia/Seoul")
    @Transactional
    public void checkEnrollmentIntegrity() {
        List<Payment> successPayments = paymentRepository.findByStatusAndCreatedAtBefore(
                "SUCCESS", LocalDateTime.now());

        int fixedCount = 0;
        for (Payment payment : successPayments) {
            boolean enrolled = enrollmentRepository.existsByMemberIdAndCourseId(
                    payment.getMember().getId(), payment.getCourse().getId());

            if (!enrolled) {
                Enrollment enrollment = Enrollment.builder()
                        .member(payment.getMember())
                        .course(payment.getCourse())
                        .build();
                enrollmentRepository.save(enrollment);
                fixedCount++;
                log.warn("[정합성] 수강등록 복구: memberId={}, courseId={}",
                        payment.getMember().getId(), payment.getCourse().getId());
            }
        }

        if (fixedCount > 0) {
            log.info("[정합성] 수강등록 복구 완료: {}건", fixedCount);
        }
    }
}
