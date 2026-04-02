import SwiftUI

struct CourseDetailView: View {
    let courseId: Int

    @State private var course: CourseDetail?
    @State private var isLoading = true
    @State private var isEnrolled = false
    @State private var showEnrollSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else if let course = course {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 썸네일 (직각, 풀 너비)
                        ZStack {
                            if let urlStr = course.thumbnailUrl, let url = URL(string: urlStr) {
                                AsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(16/9, contentMode: .fill)
                                } placeholder: {
                                    Rectangle().fill(Color(.systemGray5)).aspectRatio(16/9, contentMode: .fill)
                                        .overlay { Image(systemName: "play.rectangle.fill").font(.system(size: 50)).foregroundStyle(.secondary) }
                                }
                            } else {
                                Rectangle().fill(Color(.systemGray5)).aspectRatio(16/9, contentMode: .fill)
                                    .overlay { Image(systemName: "play.rectangle.fill").font(.system(size: 50)).foregroundStyle(.secondary) }
                            }
                        }
                        .frame(height: 220)
                        .clipped()

                        VStack(alignment: .leading, spacing: 16) {
                            // 카테고리 + 레벨 태그
                            HStack(spacing: 8) {
                                if let category = course.category, let cat = CourseCategory(rawValue: category) {
                                    Text(cat.displayName)
                                        .font(.caption).fontWeight(.medium)
                                        .padding(.horizontal, 10).padding(.vertical, 4)
                                        .background(Color.mainCoral.opacity(0.15))
                                        .foregroundStyle(Color.mainCoral).cornerRadius(6)
                                }
                                if let level = course.level, let lev = CourseLevel(rawValue: level) {
                                    Text(lev.displayName)
                                        .font(.caption).fontWeight(.medium)
                                        .padding(.horizontal, 10).padding(.vertical, 4)
                                        .background(.orange.opacity(0.1))
                                        .foregroundStyle(.orange).cornerRadius(6)
                                }
                            }

                            // 제목
                            Text(course.title)
                                .font(.system(size: 22, weight: .bold))

                            // 강사
                            Label(course.instructorName, systemImage: "person.circle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            // 설명
                            if let description = course.description {
                                Text(description)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(4)
                            }

                            Divider()

                            // 진도율 (수강 중)
                            if let progress = course.userProgress, progress.enrollmentId != nil {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("내 진도율")
                                            .font(.headline)
                                        Spacer()
                                        Text("\(Int(progress.progressPercent))%")
                                            .font(.headline)
                                            .foregroundStyle(Color.mainCoral)
                                    }
                                    ProgressView(value: progress.progressPercent, total: 100)
                                        .tint(Color.mainCoral)
                                    Text("\(progress.completedLectures)/\(progress.totalLectures) 레슨 완료")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }

                            // 커리큘럼
                            if isEnrolled || course.userProgress?.enrollmentId != nil {
                                // 수강 중 → 강의 목록 (클릭 가능)
                                curriculumSection(course, clickable: true)
                            } else {
                                // 미수강 → 커리큘럼 미리보기 (클릭 불가)
                                curriculumSection(course, clickable: false)
                            }
                        }
                        .padding()

                        // 하단 버튼에 가려지지 않도록 여백
                        if !isEnrolled && course.userProgress?.enrollmentId == nil {
                            Spacer().frame(height: 100)
                        }
                    }
                }

                // 하단 고정 수강 신청 버튼 (미수강 시)
                if !isEnrolled && course.userProgress?.enrollmentId == nil {
                    VStack {
                        Spacer()
                        Button {
                            Task { await enrollCourse() }
                        } label: {
                            Text("수강 신청하기")
                                .font(.system(size: 17, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.mainCoral)
                                .foregroundStyle(.white)
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .background(
                            LinearGradient(colors: [.clear, Color(.systemBackground)], startPoint: .top, endPoint: .center)
                        )
                    }
                }
            }

            // 수강 신청 성공 오버레이
            if showEnrollSuccess {
                enrollSuccessOverlay
            }
        }
        .navigationTitle("강의 상세")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadCourseDetail() }
    }

    @ViewBuilder
    private func curriculumSection(_ course: CourseDetail, clickable: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("커리큘럼")
                .font(.title3).fontWeight(.bold)

            let totalLectures = course.sections.reduce(0) { $0 + ($1.lectures?.count ?? 0) }
            Text("\(course.sections.count)개 섹션 · \(totalLectures)개 레슨")
                .font(.subheadline).foregroundStyle(.secondary)

            ForEach(course.sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title)
                        .font(.headline).padding(.top, 4)

                    if let lectures = section.lectures {
                        ForEach(lectures) { lecture in
                            if clickable {
                                NavigationLink(destination: VideoPlayerView(lecture: lecture, courseTitle: course.title)) {
                                    lectureRow(lecture)
                                }
                            } else {
                                lectureRow(lecture)
                                    .opacity(0.6)
                            }
                        }
                    }
                }
            }
        }
    }

    private func lectureRow(_ lecture: Lecture) -> some View {
        HStack {
            Image(systemName: "play.circle.fill")
                .foregroundStyle(Color.mainCoral)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(lecture.title)
                    .font(.subheadline).foregroundStyle(.primary)
                Text(lecture.formattedPlayTime)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private var enrollSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.mainCoral)

                Text("수강이 신청되었습니다!")
                    .font(.system(size: 20, weight: .bold))

                Text("지금 바로 강의를 시작해보세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    withAnimation { showEnrollSuccess = false }
                } label: {
                    Text("강의 보러가기")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.mainCoral)
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 32)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func loadCourseDetail() async {
        do {
            course = try await APIService.shared.getCourseDetail(courseId: courseId)
            isEnrolled = course?.userProgress?.enrollmentId != nil
        } catch {
            print("강의 상세 로드 실패: \(error)")
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
