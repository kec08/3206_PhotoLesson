import SwiftUI

struct CourseDetailView: View {
    let courseId: Int

    @State private var course: CourseDetail?
    @State private var isLoading = true
    @State private var isEnrolled = false
    @State private var showEnrollAlert = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding(.top, 100)
            } else if let course = course {
                VStack(alignment: .leading, spacing: 20) {
                    // 헤더
                    courseHeader(course)

                    // 진도율 (수강 중인 경우)
                    if let progress = course.userProgress, progress.enrollmentId != nil {
                        progressSection(progress)
                    }

                    // 수강 신청 버튼
                    enrollButton(course)

                    Divider()

                    // 커리큘럼
                    curriculumSection(course)
                }
                .padding()
            }
        }
        .navigationTitle("강의 상세")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadCourseDetail() }
        .alert("수강 신청", isPresented: $showEnrollAlert) {
            Button("취소", role: .cancel) {}
            Button("신청하기") {
                Task { await enrollCourse() }
            }
        } message: {
            Text("이 강의를 수강하시겠습니까?")
        }
    }

    @ViewBuilder
    private func courseHeader(_ course: CourseDetail) -> some View {
        // 썸네일
        if let urlStr = course.thumbnailUrl, let url = URL(string: urlStr) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .aspectRatio(16/9, contentMode: .fill)
                    .overlay {
                        Image(systemName: "camera")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }
            .cornerRadius(12)
        }

        VStack(alignment: .leading, spacing: 8) {
            // 카테고리 & 레벨
            HStack(spacing: 8) {
                if let category = course.category, let cat = CourseCategory(rawValue: category) {
                    Text(cat.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(6)
                }
                if let level = course.level, let lev = CourseLevel(rawValue: level) {
                    Text(lev.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.1))
                        .foregroundStyle(.orange)
                        .cornerRadius(6)
                }
            }

            Text(course.title)
                .font(.title2)
                .fontWeight(.bold)

            Label(course.instructorName, systemImage: "person.circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let description = course.description {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func progressSection(_ progress: UserProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("내 진도율")
                    .font(.headline)
                Spacer()
                Text("\(Int(progress.progressPercent))%")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }

            ProgressView(value: progress.progressPercent, total: 100)
                .tint(.blue)

            Text("\(progress.completedLectures)/\(progress.totalLectures) 레슨 완료")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func enrollButton(_ course: CourseDetail) -> some View {
        if course.userProgress?.enrollmentId == nil && !isEnrolled {
            Button {
                showEnrollAlert = true
            } label: {
                Text("수강 신청하기")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .cornerRadius(12)
        } else {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("수강 중")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }

        if let errorMessage = errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private func curriculumSection(_ course: CourseDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("커리큘럼")
                .font(.title3)
                .fontWeight(.bold)

            let totalLectures = course.sections.reduce(0) { $0 + ($1.lectures?.count ?? 0) }
            Text("\(course.sections.count)개 섹션 · \(totalLectures)개 레슨")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(course.sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.title)
                        .font(.headline)
                        .padding(.top, 4)

                    if let lectures = section.lectures {
                        ForEach(lectures) { lecture in
                            NavigationLink(destination: VideoPlayerView(lecture: lecture, courseTitle: course.title)) {
                                HStack {
                                    Image(systemName: "play.circle")
                                        .foregroundStyle(.blue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lecture.title)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        Text(lecture.formattedPlayTime)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
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
