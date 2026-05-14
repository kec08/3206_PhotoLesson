import SwiftUI

struct CourseDetailView: View {
    let courseId: Int

    @EnvironmentObject var authManager: AuthManager
    @State private var course: CourseDetail?
    @State private var isLoading = true
    @State private var isEnrolled = false
    @State private var showEnrollSuccess = false
    @State private var errorMessage: String?
    @State private var expandedSections: Set<Int> = []
    @State private var navigateToPlayer = false

    private var isTeacher: Bool {
        authManager.isTeacher
    }

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else if let course = course {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 히어로 썸네일
                        heroImage(course)

                        VStack(alignment: .leading, spacing: 20) {
                            // 태그 + 제목 영역
                            courseHeader(course)

                            // 강의 정보 카드
                            courseInfoCard(course)

                            // 진도율 (수강 중)
                            if let progress = course.userProgress, progress.enrollmentId != nil {
                                progressCard(progress)
                            }

                            // 커리큘럼
                            if isEnrolled || course.userProgress?.enrollmentId != nil {
                                curriculumSection(course, clickable: true)
                            } else {
                                curriculumSection(course, clickable: false)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, isTeacher || isEnrolled || course.userProgress?.enrollmentId != nil ? 20 : 100)
                    }
                }

                // 하단 고정 수강 신청 버튼 (강사/관리자는 제외)
                if !isTeacher && !isEnrolled && course.userProgress?.enrollmentId == nil {
                    VStack(spacing: 0) {
                        Spacer()
                        enrollButton
                    }
                }
            }

            // 수강 신청 성공 오버레이
            if showEnrollSuccess {
                enrollSuccessOverlay
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToPlayer) {
            CoursePlayerView(courseId: courseId, courseTitle: course?.title ?? "")
        }
        .task { await loadCourseDetail() }
    }

    // MARK: - 히어로 이미지

    private func heroImage(_ course: CourseDetail) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let fullUrl = APIService.shared.fullImageURL(course.thumbnailUrl),
               let url = URL(string: fullUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(
                        LinearGradient(colors: [Color(.systemGray4), Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    ).aspectRatio(16/9, contentMode: .fill)
                        .overlay { ProgressView() }
                }
            } else {
                Rectangle().fill(
                    LinearGradient(colors: [Color(.systemGray4), Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                ).aspectRatio(16/9, contentMode: .fill)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                            Text("PhotoLesson")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                    }
            }

            // 그라데이션 오버레이
            LinearGradient(colors: [.clear, .clear, Color(.systemBackground).opacity(0.8)], startPoint: .top, endPoint: .bottom)
        }
        .aspectRatio(16/9, contentMode: .fit)
        .clipped()
    }

    // MARK: - 강의 헤더

    private func courseHeader(_ course: CourseDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 카테고리 + 레벨 태그
            HStack(spacing: 8) {
                if let category = course.category, let cat = CourseCategory(rawValue: category) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.mainCoral).frame(width: 6, height: 6)
                        Text(cat.displayName)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.mainCoral.opacity(0.1))
                    .foregroundStyle(Color.mainCoral)
                    .cornerRadius(8)
                }
                if let level = course.level, let lev = CourseLevel(rawValue: level) {
                    Text(lev.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(.orange.opacity(0.1))
                        .foregroundStyle(.orange)
                        .cornerRadius(8)
                }
            }

            // 제목
            Text(course.title)
                .font(.system(size: 24, weight: .bold))
                .lineSpacing(4)

            // 강사
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(.systemGray3))
                Text(course.instructorName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // 설명
            if let description = course.description {
                Text(description)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .lineSpacing(5)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - 강의 정보 카드

    private func courseInfoCard(_ course: CourseDetail) -> some View {
        let totalLectures = course.sections.reduce(0) { $0 + ($1.lectures?.count ?? 0) }

        return HStack(spacing: 0) {
            infoItem(icon: "book.closed.fill", value: "\(course.sections.count)", label: "섹션")
            dividerLine
            infoItem(icon: "play.rectangle.fill", value: "\(totalLectures)", label: "레슨")
            dividerLine
            if let price = course.price, price > 0 {
                infoItem(icon: "wonsign.circle.fill", value: "₩\(price.formatted())", label: "가격")
            } else {
                infoItem(icon: "gift.fill", value: "무료", label: "가격")
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }

    private func infoItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.mainCoral)
            Text(value)
                .font(.system(size: 16, weight: .bold))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color(.systemGray4))
            .frame(width: 1, height: 36)
    }

    // MARK: - 진도율 카드

    private func progressCard(_ progress: UserProgress) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("내 진도율")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text("\(Int(progress.progressPercent))%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.mainCoral)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.mainCoral)
                        .frame(width: geo.size.width * progress.progressPercent / 100, height: 10)
                }
            }
            .frame(height: 10)

            HStack {
                Label("\(progress.completedLectures)/\(progress.totalLectures) 레슨 완료", systemImage: "checkmark.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(16)
        .background(Color.mainCoral.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.mainCoral.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - 커리큘럼 섹션

    @ViewBuilder
    private func curriculumSection(_ course: CourseDetail, clickable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                Text("커리큘럼")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                let totalLectures = course.sections.reduce(0) { $0 + ($1.lectures?.count ?? 0) }
                Text("\(course.sections.count)개 섹션 · \(totalLectures)개 레슨")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            // 섹션 아코디언
            ForEach(course.sections) { section in
                VStack(spacing: 0) {
                    // 섹션 헤더 (탭하여 열기/닫기)
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            if expandedSections.contains(section.sectionId) {
                                expandedSections.remove(section.sectionId)
                            } else {
                                expandedSections.insert(section.sectionId)
                            }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(section.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("\(section.lectures?.count ?? 0)개 레슨")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: expandedSections.contains(section.sectionId) ? "chevron.up" : "chevron.down")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(Color(.systemGray6))
                        .cornerRadius(expandedSections.contains(section.sectionId) ? 0 : 10)
                    }

                    // 레슨 목록 (펼쳐진 경우)
                    if expandedSections.contains(section.sectionId), let lectures = section.lectures {
                        VStack(spacing: 0) {
                            ForEach(lectures) { lecture in
                                if clickable {
                                    NavigationLink(destination: VideoPlayerView(
                                        lecture: lecture,
                                        courseTitle: course.title,
                                        allLectures: course.sections.flatMap { $0.lectures ?? [] }
                                    )) {
                                        lectureRow(lecture)
                                    }
                                } else {
                                    lectureRow(lecture)
                                        .opacity(0.5)
                                }

                                if lecture.id != lectures.last?.id {
                                    Divider().padding(.leading, 48)
                                }
                            }
                        }
                        .background(Color(.systemGray6).opacity(0.5))
                        .clipShape(
                            UnevenRoundedRectangle(bottomLeadingRadius: 10, bottomTrailingRadius: 10)
                        )
                    }
                }
            }
        }
    }

    private func lectureRow(_ lecture: Lecture) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.mainCoral)

            VStack(alignment: .leading, spacing: 2) {
                Text(lecture.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(lecture.formattedPlayTime)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - 수강 신청 버튼

    private var enrollButton: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(colors: [.clear, Color(.systemBackground)], startPoint: .top, endPoint: .center)
                )
                .frame(height: 20)

            Button {
                Task { await enrollCourse() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.and.outline")
                    Text("수강 신청하기")
                }
                .font(.system(size: 17, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.mainCoral)
                .foregroundStyle(.white)
                .cornerRadius(14)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(Color(.systemBackground))
        }
    }

    // MARK: - 수강 성공 오버레이

    private var enrollSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.mainCoral.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.mainCoral)
                }

                Text("수강이 신청되었습니다!")
                    .font(.system(size: 22, weight: .bold))

                Text("지금 바로 강의를 시작해보세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    withAnimation { showEnrollSuccess = false }
                    navigateToPlayer = true
                } label: {
                    Text("강의 보러가기")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.mainCoral)
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
            )
            .padding(.horizontal, 32)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Data

    private func loadCourseDetail() async {
        do {
            course = try await APIService.shared.getCourseDetail(courseId: courseId)
            isEnrolled = course?.userProgress?.enrollmentId != nil
            // 기본으로 모든 섹션 펼침
            if let sections = course?.sections {
                expandedSections = Set(sections.map { $0.sectionId })
            }
        } catch {
            // 에러 처리
        }
        isLoading = false
    }

    private func enrollCourse() async {
        do {
            _ = try await APIService.shared.enroll(courseId: courseId)
            isEnrolled = true
            await loadCourseDetail()
            withAnimation(.spring()) {
                showEnrollSuccess = true
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "수강 신청에 실패했습니다."
        }
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(courseId: 101)
    }
    .environmentObject(AuthManager())
}
