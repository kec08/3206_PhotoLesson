import SwiftUI
import WebKit

struct PaymentSheet: View {
    let course: CourseDetail
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showTossWebView = false
    @State private var paymentRequest: PaymentRequestResponse?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        courseInfoSection
                        priceSection
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

                payButton
            }
            .navigationTitle("결제")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { onCancel() }
                }
            }
            .fullScreenCover(isPresented: $showTossWebView) {
                if let req = paymentRequest {
                    TossPaymentWebView(
                        clientKey: req.clientKey,
                        orderId: req.orderId,
                        orderName: req.orderName,
                        amount: req.amount,
                        onSuccess: { paymentKey, orderId, amount in
                            showTossWebView = false
                            Task { await confirmPayment(paymentKey: paymentKey, orderId: orderId, amount: amount) }
                        },
                        onFail: { message in
                            showTossWebView = false
                            errorMessage = message
                        },
                        onCancel: {
                            showTossWebView = false
                        }
                    )
                }
            }
        }
    }

    // MARK: - 강의 정보

    private var courseInfoSection: some View {
        HStack(spacing: 14) {
            if let fullUrl = APIService.shared.fullImageURL(course.thumbnailUrl),
               let url = URL(string: fullUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
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
                Task { await startPayment() }
            } label: {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView().tint(.white)
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

    // MARK: - 결제 시작

    private func startPayment() async {
        isProcessing = true
        errorMessage = nil

        do {
            let req = try await APIService.shared.requestPayment(courseId: Int(course.courseId))
            paymentRequest = req
            isProcessing = false
            showTossWebView = true
        } catch let error as APIError {
            errorMessage = error.errorDescription
            isProcessing = false
        } catch {
            errorMessage = "결제 준비 중 오류가 발생했습니다."
            isProcessing = false
        }
    }

    // MARK: - 결제 승인

    private func confirmPayment(paymentKey: String, orderId: String, amount: Int) async {
        isProcessing = true
        do {
            let confirmed = try await APIService.shared.confirmPayment(
                paymentKey: paymentKey,
                orderId: orderId,
                amount: amount
            )
            if confirmed.status == "SUCCESS" {
                onSuccess()
            } else {
                errorMessage = "결제 승인에 실패했습니다."
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "결제 승인 중 오류가 발생했습니다."
        }
        isProcessing = false
    }
}

// MARK: - 토스페이먼츠 웹뷰

struct TossPaymentWebView: UIViewControllerRepresentable {
    let clientKey: String
    let orderId: String
    let orderName: String
    let amount: Int
    let onSuccess: (String, String, Int) -> Void // paymentKey, orderId, amount
    let onFail: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> TossPaymentViewController {
        let vc = TossPaymentViewController()
        vc.clientKey = clientKey
        vc.orderId = orderId
        vc.orderName = orderName
        vc.amount = amount
        vc.onSuccess = onSuccess
        vc.onFail = onFail
        vc.onCancel = onCancel
        return vc
    }

    func updateUIViewController(_ uiViewController: TossPaymentViewController, context: Context) {}
}

class TossPaymentViewController: UIViewController, WKNavigationDelegate {
    var clientKey = ""
    var orderId = ""
    var orderName = ""
    var amount = 0
    var onSuccess: ((String, String, Int) -> Void)?
    var onFail: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        view.addSubview(webView)

        // 닫기 버튼
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("닫기", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        loadPaymentPage()
    }

    @objc private func closeTapped() {
        onCancel?()
    }

    private func loadPaymentPage() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <script src="https://js.tosspayments.com/v1/payment"></script>
        </head>
        <body>
            <script>
                var tossPayments = TossPayments('\(clientKey)');
                tossPayments.requestPayment('카드', {
                    amount: \(amount),
                    orderId: '\(orderId)',
                    orderName: '\(orderName.replacingOccurrences(of: "'", with: "\\'"))',
                    successUrl: 'photolesson://payment/success',
                    failUrl: 'photolesson://payment/fail'
                }).catch(function(error) {
                    if (error.code === 'USER_CANCEL') {
                        window.location.href = 'photolesson://payment/cancel';
                    } else {
                        window.location.href = 'photolesson://payment/fail?message=' + encodeURIComponent(error.message);
                    }
                });
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://js.tosspayments.com"))
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = url.absoluteString

        // 성공 콜백
        if urlString.starts(with: "photolesson://payment/success") {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let paymentKey = components?.queryItems?.first(where: { $0.name == "paymentKey" })?.value ?? ""
            let orderId = components?.queryItems?.first(where: { $0.name == "orderId" })?.value ?? ""
            let amount = Int(components?.queryItems?.first(where: { $0.name == "amount" })?.value ?? "0") ?? 0
            onSuccess?(paymentKey, orderId, amount)
            decisionHandler(.cancel)
            return
        }

        // 실패 콜백
        if urlString.starts(with: "photolesson://payment/fail") {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let message = components?.queryItems?.first(where: { $0.name == "message" })?.value ?? "결제에 실패했습니다."
            onFail?(message)
            decisionHandler(.cancel)
            return
        }

        // 취소 콜백
        if urlString.starts(with: "photolesson://payment/cancel") {
            onCancel?()
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}
