import SwiftUI

struct TeacherStudentsView: View {
    @State private var students: [StudentProgress] = []
    @State private var isLoading = true
    @State private var courseNames: [Int: String] = [:] // userId -> 수강 강의명

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("회원 목록 로딩 중...")
                } else if students.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("아직 수강생이 없습니다")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List(students) { student in
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
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("내 회원")
            .task { await loadStudents() }
            .refreshable { await loadStudents() }
        }
    }

    private func loadStudents() async {
        isLoading = true
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
            students = allStudents
        } catch {
            // 에러 처리
        }
        isLoading = false
    }
}
