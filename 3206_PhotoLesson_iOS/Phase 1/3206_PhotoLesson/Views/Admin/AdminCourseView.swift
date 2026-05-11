import SwiftUI

struct AdminCourseView: View {
    @State private var courses: [CourseListItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

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
                                HStack {
                                    Text("\(course.sectionCount)섹션 · \(course.lectureCount)레슨")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
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
        }
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

    private func deleteCourse(at offsets: IndexSet) {
        for index in offsets {
            let course = courses[index]
            Task {
                do {
                    try await APIService.shared.deleteTeacherCourse(courseId: course.courseId)
                    courses.remove(at: index)
                } catch {
                    errorMessage = "삭제 실패: \(error.localizedDescription)"
                }
            }
        }
    }
}
