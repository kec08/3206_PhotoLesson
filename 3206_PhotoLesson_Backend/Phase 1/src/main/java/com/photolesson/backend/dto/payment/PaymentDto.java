package com.photolesson.backend.dto.payment;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentDto {
    private Long paymentId;
    private Long memberId;
    private String memberName;
    private Long courseId;
    private String courseTitle;
    private String orderId;
    private Integer amount;
    private String status;
    private String method;
    private String receiptUrl;
    private LocalDateTime createdAt;
}
