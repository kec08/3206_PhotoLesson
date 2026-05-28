import SwiftUI

struct PaymentSheet: View {
    let course: CourseDetail
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var paymentComplete = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // 강의 정보
                        courseInfoSection

                        // 결제 금액
                        priceSection

                        // 결제 수단 (토스페이먼츠)
                        paymentMethodSection

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }
                    }
                    .padding(20)
                }

                // 하단 결제 버튼
                payButton
            }
            .navigationTitle("결제")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { onCancel() }
                }
            }
        }
    }

    // MARK: - 강의 정보

    private var courseInfoSection: some View {
        HStack(spacing: 14) {
            // 썸네일
            if let fullUrl = APIService.shared.fullImageURL(course.thumbnailUrl),
               let url = URL(string: fullUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color(.systemGray5))
                }
                .frame(width: 80, height: 60)
                .cornerRadius(10)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                Text(course.instructorName)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    // MARK: - 결제 금액

    private var priceSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("강의 가격")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("₩\((course.price ?? 0).formatted())")
            }

            Divider()

            HStack {
                Text("총 결제 금액")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                Text("₩\((course.price ?? 0).formatted())")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.mainCoral)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    // MARK: - 결제 수단

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("결제 수단")
                .font(.system(size: 15, weight: .semibold))

            HStack(spacing: 12) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("토스페이먼츠")
                        .font(.system(size: 15, weight: .medium))
                    Text("카드 결제")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
            .padding(14)
            .background(Color.blue.opacity(0.06))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - 결제 버튼

    private var payButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                Task { await processPayment() }
            } label: {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "lock.fill")
                        Text("₩\((course.price ?? 0).formatted()) 결제하기")
                    }
                }
                .font(.system(size: 17, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isProcessing ? Color.gray : Color.mainCoral)
                .foregroundStyle(.white)
                .cornerRadius(14)
            }
            .disabled(isProcessing)
            .padding(20)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - 결제 처리

    private func processPayment() async {
        isProcessing = true
        errorMessage = nil

        do {
            // 1. 결제 요청 → orderId 받기
            let paymentRequest = try await APIService.shared.requestPayment(courseId: Int(course.courseId))

            // 2. 토스페이먼츠 승인 (실제로는 토스 SDK 웹뷰를 통해 처리)
            //    여기서는 백엔드에 직접 confirm 호출 (테스트 모드)
            let confirmed = try await APIService.shared.confirmPayment(
                paymentKey: "test_\(paymentRequest.orderId)",
                orderId: paymentRequest.orderId,
                amount: paymentRequest.amount
            )

            if confirmed.status == "SUCCESS" {
                onSuccess()
            } else {
                errorMessage = "결제에 실패했습니다."
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "결제 중 오류가 발생했습니다: \(error.localizedDescription)"
        }

        isProcessing = false
    }
}
