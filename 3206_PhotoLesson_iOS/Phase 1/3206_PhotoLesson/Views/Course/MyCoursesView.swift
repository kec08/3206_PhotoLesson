import SwiftUI

struct MyCoursesView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var progressData: ProgressResponse?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("강의를 불러오는 중...")
                } else if let progress = progressData, !progress.progress.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(progress.progress) { course in
                                NavigationLink(destination: CoursePlayerView(courseId: course.courseId, courseTitle: course.courseTitle)) {
                                    enrolledCard(course)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "play.rectangle")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("수강 중인 강의가 없습니다")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("홈에서 강의를 수강 신청해보세요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("내 강의")
            .task { await loadProgress() }
            .refreshable { await loadProgress() }
        }
    }

    private func enrolledCard(_ course: EnrolledCourse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(course.courseTitle)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(2)
                .foregroundStyle(.primary)

            ProgressView(value: course.progressPercent, total: 100)
                .tint(Color.mainCoral)

            HStack {
                Text("\(course.completedLectures)/\(course.totalLectures) 레슨")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(course.progressPercent))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.mainCoral)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func loadProgress() async {
        isLoading = true
        guard let userId = authManager.currentUserId else {
            isLoading = false
            return
        }
        do {
            progressData = try await APIService.shared.getProgress(userId: userId)
        } catch {
            print("수강 정보 로드 실패: \(error)")
        }
        isLoading = false
    }
}

// MARK: - 강의 플레이어 뷰 (유튜브 재생목록 스타일)
struct CoursePlayerView: View {
    let courseId: Int
    let courseTitle: String

    @State private var course: CourseDetail?
    @State private var isLoading = true
    @State private var selectedLecture: Lecture?
    @State private var showPlaylist = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let course = course {
                VStack(spacing: 0) {
                    // 영상 영역
                    if let lecture = selectedLecture ?? firstLecture(course) {
                        VideoPlayerView(lecture: lecture, courseTitle: course.title)
                    }
                }

                // 하단 재생목록 버튼
                if !showPlaylist {
                    VStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showPlaylist = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text("재생목록")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                let total = course.sections.reduce(0) { $0 + ($1.lectures?.count ?? 0) }
                                Text("\(total)개 강의")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.up")
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 10, y: -2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .navigationTitle("강의")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadCourse() }
        .sheet(isPresented: $showPlaylist) {
            playlistSheet
        }
    }

    // MARK: - 재생목록 시트
    private var playlistSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let course = course {
                        ForEach(course.sections) { section in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(section.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)

                                if let lectures = section.lectures {
                                    ForEach(lectures) { lecture in
                                        Button {
                                            selectedLecture = lecture
                                            showPlaylist = false
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: selectedLecture?.lectureId == lecture.lectureId ? "play.circle.fill" : "play.circle")
                                                    .foregroundStyle(selectedLecture?.lectureId == lecture.lectureId ? Color.mainCoral : .secondary)
                                                    .font(.title3)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(lecture.title)
                                                        .font(.system(size: 15, weight: selectedLecture?.lectureId == lecture.lectureId ? .bold : .regular))
                                                        .foregroundStyle(selectedLecture?.lectureId == lecture.lectureId ? Color.mainCoral : .primary)
                                                        .multilineTextAlignment(.leading)
                                                    Text(lecture.formattedPlayTime)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }

                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(selectedLecture?.lectureId == lecture.lectureId ? Color.mainCoral.opacity(0.08) : Color.clear)
                                        }

                                        Divider().padding(.leading, 52)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("재생목록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") {
                        showPlaylist = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func firstLecture(_ course: CourseDetail) -> Lecture? {
        course.sections.first?.lectures?.first
    }

    private func loadCourse() async {
        do {
            course = try await APIService.shared.getCourseDetail(courseId: courseId)
            if let first = course.flatMap({ firstLecture($0) }) {
                selectedLecture = first
            }
        } catch {
            print("강의 로드 실패: \(error)")
        }
        isLoading = false
    }
}
