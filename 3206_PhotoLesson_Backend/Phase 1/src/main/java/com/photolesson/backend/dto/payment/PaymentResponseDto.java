package com.photolesson.backend.dto.payment;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PaymentResponseDto {
    private String orderId;
    private Integer amount;
    private String clientKey;
    private String orderName;
    private Long courseId;
}
