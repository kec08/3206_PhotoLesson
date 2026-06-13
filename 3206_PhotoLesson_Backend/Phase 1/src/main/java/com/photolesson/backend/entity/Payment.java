package com.photolesson.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "payments", indexes = {
        @Index(name = "idx_payment_member", columnList = "member_id"),
        @Index(name = "idx_payment_course", columnList = "course_id"),
        @Index(name = "idx_payment_status", columnList = "status")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Payment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "course_id", nullable = false)
    private Course course;

    @Column(name = "order_id", unique = true, nullable = false, length = 100)
    private String orderId;

    @Column(name = "payment_key", unique = true, length = 200)
    private String paymentKey;

    @Column(nullable = false)
    private Integer amount;

    @Column(length = 20, nullable = false)
    @Builder.Default
    private String status = "PENDING"; // PENDING, SUCCESS, FAILED, REFUNDED

    @Column(length = 50)
    private String method; // 카드, 계좌이체 등

    @Column(name = "receipt_url", length = 500)
    private String receiptUrl;

    @Column(name = "fail_reason", length = 500)
    private String failReason;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
