import SwiftUI
import PhotosUI

struct MyPageView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var user: User?
    @State private var progressData: ProgressResponse?
    @State private var isLoading = true
    @State private var portfolios: [Portfolio] = []
    @State private var portfolioData: [(portfolio: Portfolio, images: [PortfolioImage])] = []
    @State private var showEditProfile = false
    @State private var editName = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var myStudents: [StudentProgress] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileSection

                    if authManager.isStudent {
                        overallProgressSection(progressData)
                    }

                    if authManager.currentRole == "TEACHER" {
                        Divider()
                            .padding(.horizontal)

                        myStudentsSection
                    } else if authManager.isStudent {
                        Divider()
                            .padding(.horizontal)

                        portfolioFeedSection
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
            .sheet(isPresented: $showEditProfile) {
                editProfileSheet
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                if let item = newValue {
                    Task { await uploadProfileImage(item: item) }
                }
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
            // 에러 처리
        }
    }

    private func uploadProfileImage(item: PhotosPickerItem) async {
        isUploadingPhoto = true
        guard let userId = authManager.currentUserId else {
            isUploadingPhoto = false
            return
        }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                // HEIC → JPEG 변환
                let jpegData: Data
                if let uiImage = UIImage(data: data),
                   let converted = uiImage.jpegData(compressionQuality: 0.8) {
                    jpegData = converted
                } else {
                    jpegData = data
                }
                user = try await APIService.shared.uploadProfileImage(userId: userId, imageData: jpegData)
            }
        } catch {
            // 에러 처리
        }
        selectedPhotoItem = nil
        isUploadingPhoto = false
    }

    private var profileSection: some View {
        HStack(spacing: 16) {
            // 프로필 이미지 (탭하면 PhotosPicker)
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if isUploadingPhoto {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 70, height: 70)
                            .overlay { ProgressView() }
                    } else if let urlStr = user?.profileImageUrl,
                              let fullUrl = APIService.shared.fullImageURL(urlStr),
                              let url = URL(string: fullUrl) {
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

                    // 카메라 뱃지
                    Circle()
                        .fill(Color.mainCoral)
                        .frame(width: 22, height: 22)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.white)
                        }
                }
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

    // MARK: - 내 회원 (강사용)
    private var myStudentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("내 회원")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("\(myStudents.count)명")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if myStudents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("아직 수강생이 없습니다")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(myStudents) { student in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.secondary)
                            }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(student.fullName)
                                .font(.system(size: 15, weight: .semibold))
                            Text(student.email)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(student.progressPercent))%")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.mainCoral)
                            Text("\(student.completedLectures)/\(student.totalLectures) 완료")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }
        }
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
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ], spacing: 2) {
                    ForEach(portfolioData, id: \.portfolio.portfolioId) { item in
                        NavigationLink(destination: PortfolioFeedView(portfolio: item.portfolio, images: item.images)) {
                            if let firstImage = item.images.first,
                               let urlStr = APIService.shared.fullImageURL(firstImage.thumbnailUrl ?? firstImage.imageUrl),
                               let url = URL(string: urlStr) {
                                Color.clear
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let img):
                                                img.resizable().scaledToFill()
                                            default:
                                                Color(.systemGray5)
                                            }
                                        }
                                    )
                                    .clipped()
                            } else {
                                Color(.systemGray5)
                                    .aspectRatio(1, contentMode: .fit)
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
            // 에러 처리
        }

        if authManager.isTeacher {
            // 강사: 내 강의의 수강생 목록 로드
            do {
                let dashboard = try await APIService.shared.getTeacherDashboard()
                var allStudents: [StudentProgress] = []
                for course in dashboard.courses {
                    if course.studentCount > 0 {
                        let courseDash = try await APIService.shared.getCourseDashboard(courseId: course.courseId)
                        for student in courseDash.students {
                            if !allStudents.contains(where: { $0.userId == student.userId }) {
                                allStudents.append(student)
                            }
                        }
                    }
                }
                myStudents = allStudents
            } catch {
                // 에러 처리
            }
        } else {
            // 학생: 포트폴리오 로드
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
                // 에러 처리
            }
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
