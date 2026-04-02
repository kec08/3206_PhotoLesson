import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoURL: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let embedURL = convertToEmbedURL(videoURL)
        if let url = URL(string: embedURL) {
            webView.load(URLRequest(url: url))
        }
    }

    /// youtube.com/watch?v=ID → youtube.com/embed/ID 변환
    private func convertToEmbedURL(_ urlString: String) -> String {
        // 이미 embed URL이면 그대로
        if urlString.contains("/embed/") { return urlString }

        // watch?v=ID 형식 → embed/ID
        if urlString.contains("watch?v="),
           let videoId = URLComponents(string: urlString)?
            .queryItems?.first(where: { $0.name == "v" })?.value {
            return "https://www.youtube.com/embed/\(videoId)?playsinline=1"
        }

        // youtu.be/ID 형식 → embed/ID
        if urlString.contains("youtu.be/"),
           let videoId = urlString.split(separator: "/").last {
            return "https://www.youtube.com/embed/\(videoId)?playsinline=1"
        }

        return urlString
    }
}

struct VideoPlayerView: View {
    let lecture: Lecture
    let courseTitle: String

    @State private var showCompletionAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // YouTube 웹뷰
            if let videoUrl = lecture.videoUrl, !videoUrl.isEmpty {
                YouTubePlayerView(videoURL: videoUrl)
                    .frame(height: 220)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 220)
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
            ScrollView {
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
                        showCompletionAlert = true
                    } label: {
                        Label("시청 완료", systemImage: "checkmark.circle")
                            .font(.system(size: 17, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.mainCoral)
                            .foregroundStyle(.white)
                            .cornerRadius(14)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            saveWatchHistory()
        }
        .alert("시청 완료", isPresented: $showCompletionAlert) {
            Button("확인") {
                Task { await markCompleted() }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 레슨을 완료 처리하시겠습니까?")
        }
    }

    private func saveWatchHistory() {
        Task {
            _ = try? await APIService.shared.recordWatchHistory(
                lectureId: lecture.lectureId,
                lastPosition: 0
            )
        }
    }

    private func markCompleted() async {
        _ = try? await APIService.shared.recordWatchHistory(
            lectureId: lecture.lectureId,
            lastPosition: lecture.playTime
        )
        dismiss()
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
