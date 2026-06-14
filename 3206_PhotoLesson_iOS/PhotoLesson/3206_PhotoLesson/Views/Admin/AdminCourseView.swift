import SwiftUI

struct AdminCourseView: View {
    @State private var courses: [CourseListItem] = []
    @State private var isLoading = true
    @State private var courseToDelete: CourseListItem?
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("강의 목록 로딩 중...")
                } else if courses.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("등록된 강의가 없습니다")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(courses) { course in
                            NavigationLink(destination: AdminCourseDetailView(courseId: course.courseId, onUpdate: { await loadCourses() })) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(course.title)
                                        .font(.system(size: 15, weight: .semibold))
                                    HStack {
                                        Text(course.category ?? "")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("강사: \(course.instructorName)")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                    Text("\(course.sectionCount)섹션 · \(course.lectureCount)레슨")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: confirmDelete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("강의 관리")
            .task { await loadCourses() }
            .refreshable { await loadCourses() }
            .alert("강의 삭제", isPresented: $showDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    if let course = courseToDelete {
                        Task {
                            do {
                                try await APIService.shared.deleteTeacherCourse(courseId: course.courseId)
                                courses.removeAll { $0.courseId == course.courseId }
                            } catch {
                                await loadCourses()
                            }
                        }
                    }
                }
            } message: {
                Text("\"\(courseToDelete?.title ?? "")\" 강의를 삭제하시겠습니까?")
            }
        }
    }

    private func loadCourses() async {
        isLoading = true
        do {
            let response = try await APIService.shared.getCourses(page: 0, size: 100)
            courses = response.content
        } catch { }
        isLoading = false
    }

    private func confirmDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            courseToDelete = courses[index]
            showDeleteAlert = true
        }
    }
}

// MARK: - 관리자 강의 상세 (수정 + 섹션 관리 + 삭제)

struct AdminCourseDetailView: View {
    let courseId: Int
    let onUpdate: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var course: CourseDetail?
    @State private var isLoading = true
    @State private var editTitle = ""
    @State private var editDescription = ""
    @State private var editCategory = "PORTRAIT"
    @State private var editLevel = "BEGINNER"
    @State private var showDeleteAlert = false
    @State private var errorMessage: String?
    @State private var showError = false

    // 섹션 수정
    @State private var editingSectionId: Int?
    @State private var editSectionTitle = ""
    @State private var showSectionEdit = false

    // 레슨 수정
    @State private var editingLectureId: Int?
    @State private var editLectureTitle = ""
    @State private var editLectureUrl = ""
    @State private var showLectureEdit = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let course = course {
                Form {
                    // 강의 기본 정보
                    SwiftUI.Section("강의 정보") {
                        TextField("제목", text: $editTitle)
                        TextField("설명", text: $editDescription)
                        Picker("카테고리", selection: $editCategory) {
                            Text("인물").tag("PORTRAIT")
                            Text("풍경").tag("LANDSCAPE")
                            Text("음식").tag("FOOD")
                            Text("스트릿").tag("STREET")
                            Text("매크로").tag("MACRO")
                        }
                        Picker("레벨", selection: $editLevel) {
                            Text("초급").tag("BEGINNER")
                            Text("중급").tag("INTERMEDIATE")
                            Text("고급").tag("ADVANCED")
                        }
                    }

                    // 섹션 목록
                    SwiftUI.Section("섹션 / 레슨") {
                        ForEach(course.sections) { section in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(section.title)
                                        .font(.system(size: 15, weight: .semibold))
                                    Spacer()
                                    Button {
                                        editingSectionId = section.sectionId
                                        editSectionTitle = section.title
                                        showSectionEdit = true
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.mainCoral)
                                    }
                                    .buttonStyle(.borderless)

                                    Button {
                                        Task { await deleteSection(sectionId: section.sectionId) }
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.borderless)
                                }

                                if let lectures = section.lectures {
                                    ForEach(lectures) { lecture in
                                        Button {
                                            editingLectureId = lecture.lectureId
                                            editLectureTitle = lecture.title
                                            editLectureUrl = lecture.videoUrl ?? ""
                                            showLectureEdit = true
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "play.circle")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(.secondary)
                                                VStack(alignment: .leading, spacing: 1) {
                                                    Text(lecture.title)
                                                        .font(.system(size: 13))
                                                        .foregroundStyle(.primary)
                                                    if let url = lecture.videoUrl, !url.isEmpty {
                                                        Text(url)
                                                            .font(.system(size: 10))
                                                            .foregroundStyle(.tertiary)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                Spacer()
                                                Image(systemName: "pencil")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(Color.mainCoral)
                                            }
                                        }
                                        .buttonStyle(.borderless)
                                        .padding(.leading, 8)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // 삭제 버튼
                    SwiftUI.Section {
                        Button("강의 삭제", role: .destructive) {
                            showDeleteAlert = true
                        }
                    }
                }
            }
        }
        .navigationTitle("강의 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") {
                    Task { await saveCourse() }
                }
                .disabled(editTitle.isEmpty)
            }
        }
        .task { await loadCourse() }
        .alert("강의 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                Task {
                    try? await APIService.shared.deleteTeacherCourse(courseId: courseId)
                    await onUpdate()
                    dismiss()
                }
            }
        } message: {
            Text("이 강의를 삭제하시겠습니까?")
        }
        .sheet(isPresented: $showSectionEdit) {
            NavigationStack {
                Form {
                    SwiftUI.Section("섹션 제목") {
                        TextField("섹션 제목을 입력하세요", text: $editSectionTitle)
                    }
                }
                .navigationTitle("섹션 수정")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { showSectionEdit = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") {
                            if let sectionId = editingSectionId {
                                Task {
                                    await updateSection(sectionId: sectionId, title: editSectionTitle)
                                    showSectionEdit = false
                                }
                            }
                        }
                        .disabled(editSectionTitle.isEmpty)
                    }
                }
            }
            .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $showLectureEdit) {
            NavigationStack {
                Form {
                    SwiftUI.Section("레슨 정보") {
                        TextField("레슨 제목", text: $editLectureTitle)
                        TextField("YouTube URL", text: $editLectureUrl)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                    }
                }
                .navigationTitle("레슨 수정")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") { showLectureEdit = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") {
                            if let lectureId = editingLectureId {
                                Task {
                                    await updateLecture(lectureId: lectureId, title: editLectureTitle, videoUrl: editLectureUrl)
                                    showLectureEdit = false
                                }
                            }
                        }
                        .disabled(editLectureTitle.isEmpty)
                    }
                }
            }
            .presentationDetents([.height(250)])
        }
        .alert("오류", isPresented: $showError) {
            Button("확인") { }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadCourse() async {
        do {
            course = try await APIService.shared.getCourseDetail(courseId: courseId)
            if let c = course {
                editTitle = c.title
                editDescription = c.description ?? ""
                editCategory = c.category ?? "PORTRAIT"
                editLevel = c.level ?? "BEGINNER"
            }
        } catch { }
        isLoading = false
    }

    private func saveCourse() async {
        let request = TeacherCourseRequest(
            title: editTitle,
            description: editDescription,
            category: editCategory,
            level: editLevel,
            price: course?.price,
            thumbnailUrl: course?.thumbnailUrl,
            sections: nil
        )
        do {
            try await APIService.shared.updateTeacherCourse(courseId: courseId, request)
            await onUpdate()
            dismiss()
        } catch {
            errorMessage = "수정 실패: \(error.localizedDescription)"
            showError = true
        }
    }

    private func updateSection(sectionId: Int, title: String) async {
        do {
            try await APIService.shared.updateSection(sectionId: sectionId, title: title)
            await loadCourse()
        } catch {
            errorMessage = "섹션 수정 실패: \(error.localizedDescription)"
            showError = true
        }
    }

    private func deleteSection(sectionId: Int) async {
        do {
            try await APIService.shared.deleteSection(sectionId: sectionId)
            await loadCourse()
        } catch {
            errorMessage = "섹션 삭제 실패: \(error.localizedDescription)"
            showError = true
        }
    }

    private func updateLecture(lectureId: Int, title: String, videoUrl: String) async {
        do {
            try await APIService.shared.updateLecture(lectureId: lectureId, title: title, videoUrl: videoUrl)
            await loadCourse()
        } catch {
            errorMessage = "레슨 수정 실패: \(error.localizedDescription)"
            showError = true
        }
    }
}
