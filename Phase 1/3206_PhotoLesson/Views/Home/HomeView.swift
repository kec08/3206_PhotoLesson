import SwiftUI

struct HomeView: View {
    @State private var courses: [CourseListItem] = []
    @State private var selectedCategory: CourseCategory?
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var currentPage = 0
    @State private var totalPages = 0
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 카테고리 필터
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        CategoryChip(title: "전체", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                            Task { await loadCourses() }
                        }
                        ForEach(CourseCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                                Task { await loadCourses() }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .animation(.spring(), value: selectedCategory)

                // 강의 목록
                if isLoading && courses.isEmpty {
                    Spacer()
                    ProgressView("강의를 불러오는 중...")
                    Spacer()
                } else if courses.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("강의가 없습니다")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(courses) { course in
                                NavigationLink(destination: CourseDetailView(courseId: course.courseId)) {
                                    CourseCardView(course: course)
                                }
                                .buttonStyle(.plain)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            // 페이지네이션
                            if currentPage < totalPages - 1 {
                                Button("더 보기") {
                                    currentPage += 1
                                    Task { await loadMoreCourses() }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                            }
                        }
                    }
                }
            }
            .navigationTitle("PhotoLesson")
            .searchable(text: $searchText, prompt: "강의 검색")
            .onSubmit(of: .search) {
                Task { await searchCourses() }
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty && isSearching {
                    isSearching = false
                    Task { await loadCourses() }
                }
            }
            .task { await loadCourses() }
        }
    }

    private func loadCourses() async {
        isLoading = true
        currentPage = 0
        do {
            let response = try await APIService.shared.getCourses(category: selectedCategory, page: 0)
            courses = response.content
            totalPages = response.totalPages
        } catch {
            print("강의 목록 로드 실패: \(error)")
        }
        isLoading = false
    }

    private func loadMoreCourses() async {
        do {
            let response = try await APIService.shared.getCourses(
                category: selectedCategory,
                page: currentPage
            )
            courses.append(contentsOf: response.content)
        } catch {
            print("추가 로드 실패: \(error)")
        }
    }

    private func searchCourses() async {
        guard !searchText.isEmpty else { return }
        isSearching = true
        isLoading = true
        do {
            let response = try await APIService.shared.searchCourses(keyword: searchText)
            courses = response.content
            totalPages = response.totalPages
        } catch {
            print("검색 실패: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.mainCoral : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}
