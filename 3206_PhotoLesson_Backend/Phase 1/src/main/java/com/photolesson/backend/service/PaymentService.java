package com.photolesson.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.photolesson.backend.dto.payment.*;
import com.photolesson.backend.entity.*;
import com.photolesson.backend.exception.CustomException;
import com.photolesson.backend.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Base64;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final MemberRepository memberRepository;
    private final CourseRepository courseRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final ObjectMapper objectMapper;

    @Value("${toss.client-key:test_ck_test}")
    private String tossClientKey;

    @Value("${toss.secret-key:test_sk_test}")
    private String tossSecretKey;

    @Transactional
    public PaymentResponseDto requestPayment(Long memberId, PaymentRequestDto request) {
        Member member = memberRepository.findById(memberId)
                .orElseThrow(() -> CustomException.notFound("사용자를 찾을 수 없습니다."));

        Course course = courseRepository.findById(request.getCourseId())
                .orElseThrow(() -> CustomException.notFound("강좌를 찾을 수 없습니다."));

        if (enrollmentRepository.existsByMemberIdAndCourseId(memberId, course.getId())) {
            throw CustomException.conflict("이미 수강 중인 강좌입니다.");
        }

        if (course.getPrice() == null || course.getPrice() <= 0) {
            throw CustomException.badRequest("무료 강좌는 결제 없이 수강 신청할 수 있습니다.");
        }

        String orderId = "PL-" + UUID.randomUUID().toString().substring(0, 8);

        Payment payment = Payment.builder()
                .member(member)
                .course(course)
                .orderId(orderId)
                .amount(course.getPrice())
                .build();
        paymentRepository.save(payment);

        return PaymentResponseDto.builder()
                .orderId(orderId)
                .amount(course.getPrice())
                .clientKey(tossClientKey)
                .orderName(course.getTitle())
                .courseId(course.getId())
                .build();
    }

    @Transactional
    public PaymentDto confirmPayment(PaymentConfirmDto request) {
        Payment payment = paymentRepository.findByOrderId(request.getOrderId())
                .orElseThrow(() -> CustomException.notFound("결제 정보를 찾을 수 없습니다."));

        if (!payment.getAmount().equals(request.getAmount())) {
            throw CustomException.badRequest("결제 금액이 일치하지 않습니다.");
        }

        try {
            String secretKey = Base64.getEncoder().encodeToString((tossSecretKey + ":").getBytes());
            String body = objectMapper.writeValueAsString(
                    java.util.Map.of("paymentKey", request.getPaymentKey(),
                            "orderId", request.getOrderId(),
                            "amount", request.getAmount()));

            HttpRequest httpRequest = HttpRequest.newBuilder()
                    .uri(URI.create("https://api.tosspayments.com/v1/payments/confirm"))
                    .header("Authorization", "Basic " + secretKey)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();

            HttpResponse<String> response = HttpClient.newHttpClient()
                    .send(httpRequest, HttpResponse.BodyHandlers.ofString());
            JsonNode data = objectMapper.readTree(response.body());

            if (response.statusCode() != 200) {
                String errorMsg = data.has("message") ? data.get("message").asText() : "결제 승인 실패";
                payment.setStatus("FAILED");
                payment.setFailReason(errorMsg);
                paymentRepository.save(payment);
                throw CustomException.badRequest(errorMsg);
            }

            // 결제 성공
            payment.setPaymentKey(request.getPaymentKey());
            payment.setStatus("SUCCESS");
            payment.setMethod(data.has("method") ? data.get("method").asText() : null);
            if (data.has("receipt") && data.get("receipt").has("url")) {
                payment.setReceiptUrl(data.get("receipt").get("url").asText());
            }
            paymentRepository.save(payment);

            // 자동 수강 등록
            if (!enrollmentRepository.existsByMemberIdAndCourseId(
                    payment.getMember().getId(), payment.getCourse().getId())) {
                Enrollment enrollment = Enrollment.builder()
                        .member(payment.getMember())
                        .course(payment.getCourse())
                        .build();
                enrollmentRepository.save(enrollment);
            }

            return toDto(payment);

        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            log.error("Toss payment confirm error", e);
            throw CustomException.badRequest("결제 승인 중 오류가 발생했습니다.");
        }
    }

    @Transactional
    public void refundPayment(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> CustomException.notFound("결제 정보를 찾을 수 없습니다."));

        if (!"SUCCESS".equals(payment.getStatus())) {
            throw CustomException.badRequest("환불할 수 없는 결제입니다.");
        }

        try {
            String secretKey = Base64.getEncoder().encodeToString((tossSecretKey + ":").getBytes());
            String body = objectMapper.writeValueAsString(
                    java.util.Map.of("cancelReason", "관리자 환불"));

            HttpRequest httpRequest = HttpRequest.newBuilder()
                    .uri(URI.create("https://api.tosspayments.com/v1/payments/" + payment.getPaymentKey() + "/cancel"))
                    .header("Authorization", "Basic " + secretKey)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body))
                    .build();

            HttpResponse<String> response = HttpClient.newHttpClient()
                    .send(httpRequest, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                throw CustomException.badRequest("환불에 실패했습니다.");
            }

            payment.setStatus("REFUNDED");
            paymentRepository.save(payment);

            // 수강 취소
            enrollmentRepository.findByMemberIdAndCourseId(
                    payment.getMember().getId(), payment.getCourse().getId()
            ).ifPresent(enrollmentRepository::delete);

        } catch (CustomException e) {
            throw e;
        } catch (Exception e) {
            throw CustomException.badRequest("환불 처리 중 오류가 발생했습니다.");
        }
    }

    public List<PaymentDto> getMemberPayments(Long memberId) {
        return paymentRepository.findByMemberIdOrderByCreatedAtDesc(memberId)
                .stream().map(this::toDto).toList();
    }

    public Page<PaymentDto> getAllPayments(Pageable pageable) {
        return paymentRepository.findAllByOrderByCreatedAtDesc(pageable).map(this::toDto);
    }

    private PaymentDto toDto(Payment p) {
        return PaymentDto.builder()
                .paymentId(p.getId())
                .memberId(p.getMember().getId())
                .memberName(p.getMember().getFullName())
                .courseId(p.getCourse().getId())
                .courseTitle(p.getCourse().getTitle())
                .orderId(p.getOrderId())
                .amount(p.getAmount())
                .status(p.getStatus())
                .method(p.getMethod())
                .receiptUrl(p.getReceiptUrl())
                .createdAt(p.getCreatedAt())
                .build();
    }
}
