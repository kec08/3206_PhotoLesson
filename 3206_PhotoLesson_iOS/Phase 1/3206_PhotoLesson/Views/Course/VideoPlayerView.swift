import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoURL: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let mobileURL = convertToMobileURL(videoURL)
        if let url = URL(string: mobileURL) {
            webView.load(URLRequest(url: url))
        }
    }

    private func convertToMobileURL(_ urlString: String) -> String {
        let videoId = extractVideoId(from: urlString)
        return "https://m.youtube.com/watch?v=\(videoId)"
    }

    private func extractVideoId(from urlString: String) -> String {
        if let components = URLComponents(string: urlString),
           let videoId = components.queryItems?.first(where: { $0.name == "v" })?.value {
            return videoId
        }
        if urlString.contains("youtu.be/"),
           let videoId = urlString.split(separator: "/").last {
            return String(videoId)
        }
        if urlString.contains("/embed/"),
           let videoId = urlString.split(separator: "/").last?.split(separator: "?").first {
            return String(videoId)
        }
        return urlString
    }
}

struct VideoPlayerView: View {
    let lecture: Lecture
    let courseTitle: String
    var onCompleted: ((Int) -> Void)? = nil  // lectureId 전달

    @State private var showCompletionAlert = false
    @State private var isCompleted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // YouTube 영상
                if let videoUrl = lecture.videoUrl, !videoUrl.isEmpty {
                    YouTubePlayerView(videoURL: videoUrl)
                        .frame(height: 350)
                } else {
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 350)
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.white.opacity(0.8))
                                Text("영상 준비 중")
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                }

                // 레슨 정보
                VStack(alignment: .leading, spacing: 16) {
                    Text(lecture.title)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(courseTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 20) {
                        Label(lecture.formattedPlayTime, systemImage: "clock")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Divider()

                    // 시청 완료 버튼
                    Button {
                        if !isCompleted {
                            showCompletionAlert = true
                        }
                    } label: {
                        Label(isCompleted ? "시청 완료됨" : "시청 완료",
                              systemImage: isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 17, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(isCompleted ? Color.green : Color.mainCoral)
                            .foregroundStyle(.white)
                            .cornerRadius(14)
                    }
                    .disabled(isCompleted)
                    .animation(.easeInOut, value: isCompleted)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("시청 완료", isPresented: $showCompletionAlert) {
            Button("확인") {
                Task { await markCompleted() }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 레슨을 완료 처리하시겠습니까?")
        }
    }

    private func markCompleted() async {
        _ = try? await APIService.shared.recordWatchHistory(
            lectureId: lecture.lectureId,
            lastPosition: lecture.playTime
        )
        isCompleted = true
        onCompleted?(lecture.lectureId)
    }
}

#Preview {
    NavigationStack {
        VideoPlayerView(
            lecture: SampleData.lecture1,
            courseTitle: "DSLR 기초 - 노출 이해하기"
        )
    }
}
