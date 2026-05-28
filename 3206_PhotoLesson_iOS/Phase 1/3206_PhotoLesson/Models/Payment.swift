import Foundation

struct PaymentRequest: Codable {
    let courseId: Int
}

struct PaymentRequestResponse: Codable {
    let orderId: String
    let amount: Int
    let clientKey: String
    let orderName: String
    let courseId: Int
}

struct PaymentConfirm: Codable {
    let paymentKey: String
    let orderId: String
    let amount: Int
}

struct PaymentResponse: Codable {
    let paymentId: Int
    let memberId: Int
    let memberName: String?
    let courseId: Int
    let courseTitle: String?
    let orderId: String
    let amount: Int
    let status: String
    let method: String?
    let receiptUrl: String?
    let createdAt: String?
}
