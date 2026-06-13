package com.photolesson.backend.dto.payment;

import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PaymentRequestDto {
    @NotNull(message = "강좌 ID는 필수입니다.")
    private Long courseId;
}
