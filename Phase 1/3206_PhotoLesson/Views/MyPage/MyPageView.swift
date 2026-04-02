import SwiftUI

struct MyPageView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var user: User?
    @State private var progressData: ProgressResponse?
    @State private var isLoading = true
    @State private var portfolios: [Portfolio] = []
    @State private var portfolioData: [(portfolio: Portfolio, images: [PortfolioImage])] = []
    @State private var showEditProfile = false
    @State private var editName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 프로필 섹션
                    profileSection

                    // 전체 학습 현황
                    overallProgressSection(progressData)

                    Divider()
                        .padding(.horizontal)

                    // 인스타그램 피드 스타일 포트폴리오
                    portfolioFeedSection
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
            .sheet(isPresented: $showEditProfile) {
                editProfileSheet
            }
        }
    }

    private var editProfileSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("이름")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    TextField("이름을 입력해주세요", text: $editName)
                        .font(.system(size: 17))
                        .padding(.bottom, 8)
                    Rectangle()
                        .fill(editName.isEmpty ? Color(.systemGray4) : Color.mainCoral)
                        .frame(height: 1.5)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)

                Spacer()
            }
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { showEditProfile = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task { await saveProfile() }
                    }
                    .disabled(editName.isEmpty)
                    .foregroundStyle(Color.mainCoral)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveProfile() async {
        guard let userId = authManager.currentUserId else { return }
        do {
            user = try await APIService.shared.updateUser(userId: userId, fullName: editName, profileImageUrl: nil)
            showEditProfile = false
        } catch {
            print("프로필 수정 실패: \(error)")
        }
    }

    private var profileSection: some View {
        HStack(spacing: 16) {
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

            Button {
                editName = user?.fullName ?? ""
                showEditProfile = true
            } label: {
                Text("편집")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.mainCoral)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mainCoral, lineWidth: 1)
                    )
            }
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
    private func overallProgressSection(_ progress: ProgressResponse?) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                StatCard(title: "수강 강의", value: "\(progress?.totalEnrolledCourses ?? 0)", icon: "book.fill")
                StatCard(title: "완료 레슨", value: "\(progress?.totalCompletedLectures ?? 0)", icon: "checkmark.circle.fill")
                StatCard(title: "전체 진도율", value: "\(Int(progress?.totalProgressPercent ?? 0))%", icon: "chart.bar.fill")
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 인스타 프로필 스타일 포트폴리오 그리드
    private var portfolioFeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("내 포트폴리오")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                NavigationLink(destination: PortfolioListView()) {
                    Text("전체보기")
                        .font(.subheadline)
                        .foregroundStyle(Color.mainCoral)
                }
            }
            .padding(.horizontal)

            if portfolioData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("아직 포트폴리오가 없습니다")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // 인스타 프로필처럼 3열 그리드 (대표 이미지 1장씩)
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ], spacing: 2) {
                    ForEach(portfolioData, id: \.portfolio.portfolioId) { item in
                        NavigationLink(destination: PortfolioFeedView(portfolio: item.portfolio, images: item.images)) {
                            // 대표 이미지 (첫 번째)
                            if let firstImage = item.images.first,
                               let urlStr = APIService.shared.fullImageURL(firstImage.thumbnailUrl ?? firstImage.imageUrl),
                               let url = URL(string: urlStr) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable().scaledToFill()
                                    default:
                                        Color(.systemGray5)
                                    }
                                }
                                .frame(height: 130)
                                .frame(maxWidth: .infinity)
                                .clipped()
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
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

        // 포트폴리오 데이터 로드 (각 포트폴리오의 이미지도 함께)
        do {
            let portfolioResponse = try await APIService.shared.getPortfolios()
            portfolios = portfolioResponse.content
            var loadedData: [(portfolio: Portfolio, images: [PortfolioImage])] = []
            for p in portfolios {
                let images = try await APIService.shared.getPortfolioImages(portfolioId: p.portfolioId)
                if !images.isEmpty {
                    loadedData.append((portfolio: p, images: images))
                }
            }
            portfolioData = loadedData
        } catch {
            print("포트폴리오 데이터 로드 실패: \(error)")
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
                .foregroundStyle(Color.mainCoral)
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

struct EnrolledCourseCard: View {
    let course: EnrolledCourse

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(course.courseTitle)
                .font(.headline)
                .lineLimit(2)

            ProgressView(value: course.progressPercent, total: 100)
                .tint(Color.mainCoral)

            HStack {
                Text("\(course.completedLectures)/\(course.totalLectures) 레슨")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(course.progressPercent))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.mainCoral)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
