import SwiftUI

struct AdminCourseView: View {
    @State private var courses: [CourseListItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var editingCourse: CourseListItem?
    @State private var showEditSheet = false
    @State private var editTitle = ""
    @State private var editDescription = ""
    @State private var editCategory = "PORTRAIT"
    @State private var editLevel = "BEGINNER"

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
                            Button {
                                editingCourse = course
                                editTitle = course.title
                                editCategory = course.category ?? "PORTRAIT"
                                editLevel = course.level ?? "BEGINNER"
                                editDescription = ""
                                showEditSheet = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(course.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.primary)
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
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteCourse)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("강의 관리")
            .task { await loadCourses() }
            .refreshable { await loadCourses() }
            .sheet(isPresented: $showEditSheet) {
                adminCourseEditSheet
            }
            .alert("오류", isPresented: .constant(errorMessage != nil)) {
                Button("확인") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var adminCourseEditSheet: some View {
        NavigationStack {
            Form {
                SwiftUI.Section("강의 정보") {
                    TextField("강의 제목", text: $editTitle)
                    TextField("강의 설명", text: $editDescription)
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

                SwiftUI.Section {
                    Button("강의 삭제", role: .destructive) {
                        Task {
                            if let course = editingCourse {
                                await deleteById(courseId: course.courseId)
                                showEditSheet = false
                            }
                        }
                    }
                }
            }
            .navigationTitle("강의 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { showEditSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            await saveCourse()
                            showEditSheet = false
                        }
                    }
                    .disabled(editTitle.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func loadCourses() async {
        isLoading = true
        do {
            let response = try await APIService.shared.getCourses(page: 0, size: 100)
            courses = response.content
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func saveCourse() async {
        guard let course = editingCourse else { return }
        let request = TeacherCourseRequest(
            title: editTitle,
            description: editDescription,
            category: editCategory,
            level: editLevel,
            price: nil,
            thumbnailUrl: nil,
            sections: nil
        )
        do {
            try await APIService.shared.updateTeacherCourse(courseId: course.courseId, request)
            await loadCourses()
        } catch {
            errorMessage = "수정 실패: \(error.localizedDescription)"
        }
    }

    private func deleteCourse(at offsets: IndexSet) {
        for index in offsets {
            let course = courses[index]
            Task {
                await deleteById(courseId: course.courseId)
            }
        }
    }

    private func deleteById(courseId: Int) async {
        do {
            try await APIService.shared.deleteTeacherCourse(courseId: courseId)
            courses.removeAll { $0.courseId == courseId }
        } catch {
            errorMessage = "삭제 실패: \(error.localizedDescription)"
        }
    }
}
