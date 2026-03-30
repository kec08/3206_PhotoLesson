import SwiftUI
import AVKit
import Combine

struct VideoPlayerView: View {
    let lecture: Lecture
    let courseTitle: String

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentPosition: Double = 0
    @State private var showCompletionAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // 비디오 플레이어
            GeometryReader { geometry in
                let playerHeight = geometry.size.width * 9 / 16
                if let player = player {
                    VideoPlayer(player: player)
                        .frame(height: playerHeight)
                } else {
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: playerHeight)
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
            }
            .frame(height: 220)

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
                        if player != nil {
                            Label(formatPosition(currentPosition), systemImage: "play.fill")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Divider()

                    // 재생 컨트롤
                    if player != nil {
                        VStack(spacing: 12) {
                            ProgressView(value: currentPosition, total: Double(lecture.playTime))
                                .tint(.blue)

                            HStack {
                                Text(formatPosition(currentPosition))
                                Spacer()
                                Text(lecture.formattedPlayTime)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }

                    // 시청 완료 버튼
                    Button {
                        showCompletionAlert = true
                    } label: {
                        Label("시청 완료", systemImage: "checkmark.circle")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { setupPlayer() }
        .onDisappear {
            saveWatchHistory()
            player?.pause()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updatePosition()
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

    private func setupPlayer() {
        if let urlStr = lecture.videoUrl, let url = URL(string: urlStr) {
            player = AVPlayer(url: url)
        }
    }

    private func updatePosition() {
        guard let player = player else { return }
        let time = player.currentTime()
        currentPosition = CMTimeGetSeconds(time)
    }

    private func formatPosition(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func saveWatchHistory() {
        let position = Int(currentPosition)
        Task {
            _ = try? await APIService.shared.recordWatchHistory(
                lectureId: lecture.lectureId,
                lastPosition: position
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
