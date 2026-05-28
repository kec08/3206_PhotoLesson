package com.photolesson.backend.controller;

import com.photolesson.backend.dto.payment.*;
import com.photolesson.backend.service.PaymentService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    @PostMapping("/request")
    public ResponseEntity<PaymentResponseDto> requestPayment(
            @RequestBody PaymentRequestDto request,
            Authentication authentication) {
        Long memberId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(paymentService.requestPayment(memberId, request));
    }

    @PostMapping("/confirm")
    public ResponseEntity<PaymentDto> confirmPayment(@RequestBody PaymentConfirmDto request) {
        return ResponseEntity.ok(paymentService.confirmPayment(request));
    }

    @GetMapping("/my")
    public ResponseEntity<List<PaymentDto>> myPayments(Authentication authentication) {
        Long memberId = (Long) authentication.getPrincipal();
        return ResponseEntity.ok(paymentService.getMemberPayments(memberId));
    }

    @PostMapping("/webhook")
    public ResponseEntity<Void> webhook(@RequestBody String body) {
        // Toss Payments webhook endpoint
        return ResponseEntity.ok().build();
    }
}
