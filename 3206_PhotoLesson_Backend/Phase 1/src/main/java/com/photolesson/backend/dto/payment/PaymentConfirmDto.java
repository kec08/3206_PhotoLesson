package com.photolesson.backend.dto.payment;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PaymentConfirmDto {
    private String paymentKey;
    private String orderId;
    private Integer amount;
}
