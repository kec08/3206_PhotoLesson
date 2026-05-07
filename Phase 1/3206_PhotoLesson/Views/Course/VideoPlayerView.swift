import SwiftUI
import WebKit

// MARK: - YouTube Player (watch 페이지 직접 로드)

struct YouTubePlayerView: UIViewRepresentable {
    let videoURL: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        // 모바일 Safari UA → YouTube가 모바일 플레이어 제공
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.navigationDelegate = context.coordinator

        loadVideo(webView: webView, context: context)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let videoId = extractVideoId(from: videoURL)
        if context.coordinator.lastVideoId != videoId {
            loadVideo(webView: webView, context: context)
        }
    }

    private func loadVideo(webView: WKWebView, context: Context) {
        let videoId = extractVideoId(from: videoURL)
        context.coordinator.lastVideoId = videoId

        // YouTube watch 페이지를 직접 로드 (embed 아님)
        let watchURL = "https://m.youtube.com/watch?v=\(videoId)"
        if let url = URL(string: watchURL) {
            webView.load(URLRequest(url: url))
        }
    }

    private func extractVideoId(from urlString: String) -> String {
        if let c = URLComponents(string: urlString),
           let v = c.queryItems?.first(where: { $0.name == "v" })?.value { return v }
        if urlString.contains("youtu.be/") {
            let parts = urlString.split(separator: "/")
            if let last = parts.last {
                return String(last.split(separator: "?").first ?? last)
            }
        }
        if urlString.contains("/embed/"),
           let v = urlString.split(separator: "/").last?.split(separator: "?").first { return String(v) }
        return urlString
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var lastVideoId: String?

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // 외부 앱 열기 시도 (유튜브 앱 등) 차단 → 웹뷰 내에서만 재생
            if let url = navigationAction.request.url,
               url.scheme == "youtube" || url.scheme == "vnd.youtube" {
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

// MARK: - Video Player View (패스트캠퍼스 스타일)

struct VideoPlayerView: View {
    let lecture: Lecture
    let courseTitle: String
    var allLectures: [Lecture] = []
    var onCompleted: ((Int) -> Void)? = nil
    var onSelectLecture: ((Lecture) -> Void)? = nil

    @State private var showCompletionAlert = false
    @State private var isCompleted = false
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) private var sizeClass

    private let tabs = ["강의소개", "댓글", "학습통계"]

    var body: some View {
        Group {
            if sizeClass == .regular {
                // iPad: 좌측 영상 + 우측 커리큘럼
                HStack(spacing: 0) {
                    leftPanel
                        .frame(maxWidth: .infinity)

                    Divider()

                    rightPanel
                        .frame(width: 360)
                }
            } else {
                // iPhone
                ScrollView {
                    VStack(spacing: 0) {
                        videoSection
                        phoneInfoSection
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(courseTitle)
        .alert("시청 완료", isPresented: $showCompletionAlert) {
            Button("확인") { Task { await markCompleted() } }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 레슨을 완료 처리하시겠습니까?")
        }
    }

    // MARK: - iPad 좌측 패널

    private var leftPanel: some View {
        ScrollView {
            VStack(spacing: 0) {
                videoSection

                // 탭 바
                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { idx in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = idx }
                        } label: {
                            VStack(spacing: 8) {
                                Text(tabs[idx])
                                    .font(.system(size: 15, weight: selectedTab == idx ? .bold : .medium))
                                    .foregroundStyle(selectedTab == idx ? Color.mainCoral : .secondary)
                                    .padding(.vertical, 12)

                                Rectangle()
                                    .fill(selectedTab == idx ? Color.mainCoral : Color.clear)
                                    .frame(height: 3)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                Divider()

                // 탭 콘텐츠
                switch selectedTab {
                case 0:
                    infoContent
                case 1:
                    CommentSectionView(lectureId: lecture.lectureId)
                case 2:
                    statsContent
                default:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - iPad 우측 패널 (커리큘럼)

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("커리큘럼")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text("\(allLectures.count)개 레슨")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(allLectures.enumerated()), id: \.element.lectureId) { idx, lec in
                        Button {
                            onSelectLecture?(lec)
                        } label: {
                            HStack(spacing: 12) {
                                // 번호
                                Text("\(idx + 1)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(lec.lectureId == lecture.lectureId ? Color.mainCoral : .secondary)
                                    .frame(width: 24)

                                // 재생 아이콘
                                Image(systemName: lec.lectureId == lecture.lectureId ? "play.fill" : "play.circle")
                                    .font(.system(size: 14))
                                    .foregroundStyle(lec.lectureId == lecture.lectureId ? Color.mainCoral : .secondary)

                                // 정보
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lec.title)
                                        .font(.system(size: 13, weight: lec.lectureId == lecture.lectureId ? .bold : .regular))
                                        .foregroundStyle(lec.lectureId == lecture.lectureId ? Color.mainCoral : .primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)

                                    Text(lec.formattedPlayTime)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(lec.lectureId == lecture.lectureId ? Color.mainCoral.opacity(0.06) : Color.clear)
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 52)
                    }
                }
            }
        }
        .background(Color(.systemGray6))
    }

    // MARK: - 영상

    private var videoSection: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let height = width * 9.0 / 16.0  // 16:9 비율 계산

            Group {
                if let videoUrl = lecture.videoUrl, !videoUrl.isEmpty {
                    YouTubePlayerView(videoURL: videoUrl)
                } else {
                    Rectangle()
                        .fill(Color.black)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text("영상 준비 중")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                }
            }
            .frame(width: width, height: height)
        }
        .aspectRatio(16/9, contentMode: .fit)
        .clipped()
    }

    // MARK: - iPhone 정보 (세로 스크롤)

    private var phoneInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(lecture.title)
                .font(.title3).fontWeight(.bold)

            Text(courseTitle)
                .font(.subheadline).foregroundStyle(.secondary)

            Label(lecture.formattedPlayTime, systemImage: "clock")
                .font(.subheadline).foregroundStyle(.secondary)

            completionButton

            Divider()

            CommentSectionView(lectureId: lecture.lectureId)
        }
        .padding()
    }

    // MARK: - 탭: 강의소개

    private var infoContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(lecture.title)
                .font(.title3).fontWeight(.bold)

            Text(courseTitle)
                .font(.subheadline).foregroundStyle(.secondary)

            Label(lecture.formattedPlayTime, systemImage: "clock")
                .font(.subheadline).foregroundStyle(.secondary)

            completionButton
        }
        .padding()
    }

    // MARK: - 탭: 학습통계

    private var statsContent: some View {
        VStack(spacing: 24) {
            // 원형 진도율
            CircularProgressView(
                progress: Double(completedCount) / Double(max(allLectures.count, 1)),
                lineWidth: 12
            )
            .frame(width: 120, height: 120)

            Text("\(completedCount)/\(allLectures.count) 레슨 완료")
                .font(.headline)

            // 레슨별 완료 현황
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(allLectures.enumerated()), id: \.element.lectureId) { idx, lec in
                    HStack(spacing: 10) {
                        Image(systemName: completedLectureIds.contains(lec.lectureId) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(completedLectureIds.contains(lec.lectureId) ? .green : .secondary)
                        Text("\(idx + 1). \(lec.title)")
                            .font(.subheadline)
                            .foregroundStyle(completedLectureIds.contains(lec.lectureId) ? .primary : .secondary)
                        Spacer()
                        Text(lec.formattedPlayTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
    }

    private var completedCount: Int {
        allLectures.filter { completedLectureIds.contains($0.lectureId) }.count
    }

    @State private var completedLectureIds: Set<Int> = []

    // MARK: - 시청 완료 버튼

    private var completionButton: some View {
        Button {
            if !isCompleted { showCompletionAlert = true }
        } label: {
            Label(isCompleted ? "시청 완료됨" : "시청 완료",
                  systemImage: isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isCompleted ? Color.green : Color.mainCoral)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .disabled(isCompleted)
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
            courseTitle: "DSLR 기초"
        )
        .environmentObject(AuthManager())
    }
}
