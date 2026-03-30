import SwiftUI

struct MyPageView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var user: User?
    @State private var progressData: ProgressResponse?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 프로필 섹션
                    profileSection

                    // 전체 학습 현황
                    if let progress = progressData {
                        overallProgressSection(progress)
                    }

                    Divider()
                        .padding(.horizontal)

                    // 수강 중인 강의 목록
                    if let progress = progressData {
                        enrolledCoursesSection(progress)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("마이페이지")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("로그아웃") {
                        authManager.logout()
                    }
                    .foregroundStyle(.red)
                }
            }
            .task { await loadData() }
            .refreshable { await loadData() }
        }
    }

    private var profileSection: some View {
        HStack(spacing: 16) {
            // 프로필 이미지
            if let urlStr = user?.profileImageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    profilePlaceholder
                }
                .frame(width: 70, height: 70)
                .clipShape(Circle())
            } else {
                profilePlaceholder
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(user?.fullName ?? "사용자")
                    .font(.title3)
                    .fontWeight(.bold)
                Text(user?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: 70, height: 70)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
    }

    @ViewBuilder
    private func overallProgressSection(_ progress: ProgressResponse) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                StatCard(title: "수강 강의", value: "\(progress.totalEnrolledCourses)", icon: "book.fill")
                StatCard(title: "완료 레슨", value: "\(progress.totalCompletedLectures)", icon: "checkmark.circle.fill")
                StatCard(title: "전체 진도율", value: "\(Int(progress.totalProgressPercent))%", icon: "chart.bar.fill")
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func enrolledCoursesSection(_ progress: ProgressResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("수강 중인 강의")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            if progress.progress.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("수강 중인 강의가 없습니다")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(progress.progress) { course in
                    NavigationLink(destination: CourseDetailView(courseId: course.courseId)) {
                        EnrolledCourseCard(course: course)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
        }
    }

    private func loadData() async {
        isLoading = true
        guard let userId = authManager.currentUserId else {
            isLoading = false
            return
        }
        do {
            async let userTask = APIService.shared.getUser(userId: userId)
            async let progressTask = APIService.shared.getProgress(userId: userId)
            user = try await userTask
            progressData = try await progressTask
        } catch {
            print("마이페이지 데이터 로드 실패: \(error)")
        }
        isLoading = false
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    MyPageView()
        .environmentObject(AuthManager())
}

#Preview("수강 강의 카드") {
    EnrolledCourseCard(course: SampleData.enrolledCourse1)
        .padding()
}

#Preview("통계 카드") {
    HStack {
        StatCard(title: "수강 강의", value: "3", icon: "book.fill")
        StatCard(title: "완료 레슨", value: "15", icon: "checkmark.circle.fill")
        StatCard(title: "전체 진도율", value: "23%", icon: "chart.bar.fill")
    }
    .padding()
}

struct EnrolledCourseCard: View {
    let course: EnrolledCourse

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(course.courseTitle)
                .font(.headline)
                .lineLimit(2)

            ProgressView(value: course.progressPercent, total: 100)
                .tint(.blue)

            HStack {
                Text("\(course.completedLectures)/\(course.totalLectures) 레슨")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(course.progressPercent))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
