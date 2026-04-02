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

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if let course = course {
                // 상단: 선택된 영상 or 첫 번째 영상
                if let lecture = selectedLecture ?? firstLecture(course) {
                    VideoPlayerView(lecture: lecture, courseTitle: course.title)
                        .frame(height: 280)
                }

                // 하단: 강의 목록 (재생목록)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(course.title)
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                        ForEach(course.sections) { section in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(section.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)

                                if let lectures = section.lectures {
                                    ForEach(lectures) { lecture in
                                        Button {
                                            selectedLecture = lecture
                                        } label: {
                                            HStack(spacing: 12) {
                                                Image(systemName: selectedLecture?.lectureId == lecture.lectureId ? "play.circle.fill" : "play.circle")
                                                    .foregroundStyle(selectedLecture?.lectureId == lecture.lectureId ? Color.mainCoral : .secondary)
                                                    .font(.title3)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(lecture.title)
                                                        .font(.system(size: 14, weight: selectedLecture?.lectureId == lecture.lectureId ? .bold : .regular))
                                                        .foregroundStyle(selectedLecture?.lectureId == lecture.lectureId ? Color.mainCoral : .primary)
                                                    Text(lecture.formattedPlayTime)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }

                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
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
        }
        .navigationTitle("강의")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadCourse() }
    }

    private func firstLecture(_ course: CourseDetail) -> Lecture? {
        course.sections.first?.lectures?.first
    }

    private func loadCourse() async {
        do {
            course = try await APIService.shared.getCourseDetail(courseId: courseId)
            // 첫 번째 강의 자동 선택
            if let first = course.flatMap({ firstLecture($0) }) {
                selectedLecture = first
            }
        } catch {
            print("강의 로드 실패: \(error)")
        }
        isLoading = false
    }
}
