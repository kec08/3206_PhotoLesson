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
        HStack(spacing: 16) {
            // 원형 진도율
            CircularProgressView(
                progress: course.progressPercent / 100.0,
                lineWidth: 6
            )
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 6) {
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
            // 에러 처리
        }
        isLoading = false
    }
}

// MARK: - 강의 플레이어 뷰 (유튜브 재생목록 스타일)
struct CoursePlayerView: View {
    let courseId: Int
    let courseTitle: String
    @EnvironmentObject var authManager: AuthManager

    @State private var course: CourseDetail?
    @State private var isLoading = true
    @State private var selectedLecture: Lecture?
    @State private var completedLectureIds: Set<Int> = []

    var body: some View {
        ZStack(alignment: .bottom) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let course = course {
                if let lecture = selectedLecture ?? firstUncompletedLecture(course) {
                    VideoPlayerView(
                        lecture: lecture,
                        courseTitle: course.title,
                        allLectures: allLectures(course),
                        onCompleted: { completedId in
                            completedLectureIds.insert(completedId)
                        },
                        onSelectLecture: { lec in
                            selectedLecture = lec
                        }
                    )
                    .id(lecture.lectureId)
                }
            }
        }
        .navigationTitle("강의")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadCourse() }
    }

    // 모든 레슨 ID 목록
    private func allLectures(_ course: CourseDetail) -> [Lecture] {
        course.sections.flatMap { $0.lectures ?? [] }
    }

    // 미완료 첫 번째 강의 찾기
    private func firstUncompletedLecture(_ course: CourseDetail) -> Lecture? {
        let all = allLectures(course)
        return all.first { !completedLectureIds.contains($0.lectureId) } ?? all.first
    }

    private func loadCourse() async {
        do {
            course = try await APIService.shared.getCourseDetail(courseId: courseId)
            await loadWatchHistory()
            // 미완료 첫 강의 자동 선택
            if let c = course {
                selectedLecture = firstUncompletedLecture(c)
            }
        } catch {
            // 에러 처리
        }
        isLoading = false
    }

    private func loadWatchHistory() async {
        guard let userId = authManager.currentUserId else { return }
        do {
            let history = try await APIService.shared.getWatchHistory(userId: userId)
            // lastPosition이 playTime과 같으면 완료로 판단
            if let c = course {
                let allLecs = allLectures(c)
                var completed = Set<Int>()
                for h in history {
                    if let lec = allLecs.first(where: { $0.lectureId == h.lectureId }) {
                        if h.lastPosition >= lec.playTime {
                            completed.insert(h.lectureId)
                        }
                    }
                }
                completedLectureIds = completed
            }
        } catch {
            // 에러 처리
        }
    }
}
