import SwiftUI
import Combine

struct HomeView: View {
    @State private var courses: [CourseListItem] = []
    @State private var selectedCategory: CourseCategory?
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var currentPage = 0
    @State private var totalPages = 0
    @State private var isSearching = false
    @State private var recentSearches: [String] = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    @State private var searchTask: Task<Void, Never>?
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 상단 헤더
                VStack(spacing: 0) {
                    // 카테고리 필터
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemBackground))

                    Divider().opacity(0.5)
                }

                // 콘텐츠
                if isLoading && courses.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("강의를 불러오는 중...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else if courses.isEmpty && isSearching {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.quaternary)
                        Text("검색 결과가 없습니다")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("다른 키워드로 검색해보세요")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                } else if courses.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.quaternary)
                        Text("강의가 없습니다")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(courses) { course in
                                NavigationLink(destination: CourseDetailView(courseId: course.courseId)) {
                                    CourseCardView(course: course)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                        // 더 보기
                        if currentPage < totalPages - 1 {
                            Button {
                                currentPage += 1
                                Task { await loadMoreCourses() }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("더 보기")
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.mainCoral)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.mainCoral.opacity(0.08))
                                .cornerRadius(10)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("PhotoLesson")
            .searchable(text: $searchText, prompt: "강의 검색")
            .searchSuggestions {
                if searchText.isEmpty && !recentSearches.isEmpty {
                    SwiftUI.Section("최근 검색어") {
                        ForEach(recentSearches, id: \.self) { term in
                            Button {
                                searchText = term
                                Task { await searchCourses() }
                            } label: {
                                Label(term, systemImage: "clock.arrow.circlepath")
                            }
                        }
                        Button("검색 기록 삭제", role: .destructive) {
                            recentSearches.removeAll()
                            UserDefaults.standard.removeObject(forKey: "recentSearches")
                        }
                    }
                }
            }
            .onSubmit(of: .search) {
                Task { await searchCourses() }
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty && isSearching {
                    isSearching = false
                    searchTask?.cancel()
                    Task { await loadCourses() }
                } else if !newValue.isEmpty {
                    searchTask?.cancel()
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        guard !Task.isCancelled else { return }
                        await searchCourses()
                    }
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
            // 에러 처리
        }
        isLoading = false
    }

    private func loadMoreCourses() async {
        do {
            let response = try await APIService.shared.getCourses(category: selectedCategory, page: currentPage)
            courses.append(contentsOf: response.content)
        } catch {
            // 에러 처리
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
            saveRecentSearch(searchText)
        } catch {
            // 에러 처리
        }
        isLoading = false
    }

    private func saveRecentSearch(_ term: String) {
        var searches = recentSearches
        searches.removeAll { $0 == term }
        searches.insert(term, at: 0)
        if searches.count > 10 { searches = Array(searches.prefix(10)) }
        recentSearches = searches
        UserDefaults.standard.set(searches, forKey: "recentSearches")
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
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.mainCoral : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 0.5)
                )
        }
    }
}
