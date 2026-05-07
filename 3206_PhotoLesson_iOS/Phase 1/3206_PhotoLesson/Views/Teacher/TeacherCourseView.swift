//
//  TeacherCourseView.swift
//  3206_PhotoLesson
//

import SwiftUI
import PhotosUI

struct TeacherCourseView: View {
    @State private var courses: [CourseListItem] = []
    @State private var dashboard: TeacherDashboard?
    @State private var isLoading = true
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 대시보드 요약
                    if let dash = dashboard {
                        dashboardSummary(dash)
                    }

                    Divider().padding(.horizontal)

                    // 내 강의 목록
                    VStack(alignment: .leading, spacing: 12) {
                        Text("내 강의")
                            .font(.title3).fontWeight(.bold)
                            .padding(.horizontal)

                        if courses.isEmpty && !isLoading {
                            VStack(spacing: 12) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                                Text("등록한 강의가 없습니다")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(courses) { course in
                                NavigationLink(destination: TeacherCourseDetailView(courseId: course.courseId, onUpdate: { await loadData() })) {
                                    teacherCourseCard(course)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("강의 관리")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task { await loadData() }
            .refreshable { await loadData() }
            .sheet(isPresented: $showCreateSheet) {
                CourseCreateView(onCreated: { await loadData() })
            }
        }
    }

    private func dashboardSummary(_ dash: TeacherDashboard) -> some View {
        HStack(spacing: 8) {
            StatCard(title: "강의 수", value: "\(dash.totalCourses)", icon: "book.fill")
            StatCard(title: "수강생", value: "\(dash.totalStudents)", icon: "person.2.fill")
            StatCard(title: "총 레슨", value: "\(dash.totalLectures)", icon: "play.rectangle.fill")
        }
        .padding(.horizontal)
    }

    private func teacherCourseCard(_ course: CourseListItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(2)
                    Text("\(course.sectionCount)개 섹션 · \(course.lectureCount)개 레슨")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let cat = CourseCategory(rawValue: course.category) {
                    Text(cat.displayName)
                        .font(.caption2).fontWeight(.medium)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.mainCoral.opacity(0.12))
                        .foregroundStyle(Color.mainCoral)
                        .cornerRadius(4)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func loadData() async {
        isLoading = true
        do {
            async let coursesTask = APIService.shared.getTeacherCourses()
            async let dashTask = APIService.shared.getTeacherDashboard()
            courses = try await coursesTask
            dashboard = try await dashTask
        } catch {
            // 에러 처리
        }
        isLoading = false
    }
}

// MARK: - 강의 생성 화면

struct CourseCreateView: View {
    let onCreated: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var courseDescription = ""
    @State private var category = "PORTRAIT"
    @State private var level = "BEGINNER"
    @State private var thumbnailUrl = ""
    @State private var sections: [SectionInput] = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var thumbnailData: Data?
    @State private var thumbnailImage: Image?

    let categories = ["PORTRAIT", "LANDSCAPE", "FOOD", "STREET", "MACRO"]
    let levels = ["BEGINNER", "INTERMEDIATE", "ADVANCED"]

    var body: some View {
        NavigationStack {
            Form {
                courseInfoSection
                thumbnailSection
                sectionsAndLessons
                errorSection
            }
            .navigationTitle("강의 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("등록") {
                        Task { await submitCourse() }
                    }
                    .disabled(title.isEmpty || courseDescription.isEmpty || isSubmitting)
                }
            }
        }
    }

    private var courseInfoSection: some View {
        SwiftUI.Section("강의 정보") {
            TextField("강의 제목", text: $title)
            TextField("강의 설명", text: $courseDescription, axis: .vertical)
                .lineLimit(3...6)
            Picker("카테고리", selection: $category) {
                ForEach(categories, id: \.self) { cat in Text(cat) }
            }
            Picker("레벨", selection: $level) {
                ForEach(levels, id: \.self) { lev in Text(lev) }
            }
        }
    }

    private var thumbnailSection: some View {
        SwiftUI.Section("썸네일 이미지") {
            if let thumbnailImage {
                thumbnailImage
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label(thumbnailData == nil ? "이미지 선택" : "이미지 변경", systemImage: "photo.on.rectangle.angled")
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data),
                       let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                        thumbnailData = jpegData
                        thumbnailImage = Image(uiImage: uiImage)
                    }
                }
            }

            if thumbnailData == nil {
                TextField("또는 URL 직접 입력", text: $thumbnailUrl)
                    .textInputAutocapitalization(.never)
            }
        }
    }

    private var sectionsAndLessons: some View {
        SwiftUI.Section {
            ForEach(sections) { sec in
                let sid = sec.id
                VStack(alignment: .leading, spacing: 8) {
                    // 섹션 헤더
                    HStack {
                        TextField("섹션 제목", text: bindTitle(of: sid))
                            .font(.headline)
                        Button(role: .destructive) {
                            sections.removeAll { $0.id == sid }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }

                    // 레슨 목록
                    if let si = sections.firstIndex(where: { $0.id == sid }) {
                        ForEach(sections[si].lectures) { lec in
                            let lid = lec.id
                            LectureRowView2(
                                lecture: lec,
                                titleBinding: bindLecture(sid: sid, lid: lid, keyPath: \.title),
                                urlBinding: bindLecture(sid: sid, lid: lid, keyPath: \.videoUrl),
                                playTimeBinding: bindLecture(sid: sid, lid: lid, keyPath: \.playTimeStr),
                                onDelete: {
                                    if let si = sections.firstIndex(where: { $0.id == sid }) {
                                        sections[si].lectures.removeAll { $0.id == lid }
                                    }
                                }
                            )
                        }
                    }

                    // 레슨 추가
                    Button {
                        withAnimation(.none) {
                            if let si = sections.firstIndex(where: { $0.id == sid }) {
                                sections[si].lectures.append(LectureInput())
                            }
                        }
                    } label: {
                        Label("레슨 추가", systemImage: "plus.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .padding(.leading, 16)
                }
                .padding(.vertical, 4)
            }

            Button {
                sections.append(SectionInput())
            } label: {
                Label("섹션 추가", systemImage: "plus.rectangle.on.rectangle")
            }
            .buttonStyle(.borderless)
        } header: {
            Text("섹션 / 레슨")
        }
    }

    // MARK: - 바인딩 헬퍼

    private func bindTitle(of sectionId: UUID) -> Binding<String> {
        Binding(
            get: { sections.first(where: { $0.id == sectionId })?.title ?? "" },
            set: { val in if let i = sections.firstIndex(where: { $0.id == sectionId }) { sections[i].title = val } }
        )
    }

    private func bindLecture(sid: UUID, lid: UUID, keyPath: WritableKeyPath<LectureInput, String>) -> Binding<String> {
        Binding(
            get: {
                guard let si = sections.firstIndex(where: { $0.id == sid }),
                      let li = sections[si].lectures.firstIndex(where: { $0.id == lid })
                else { return "" }
                return sections[si].lectures[li][keyPath: keyPath]
            },
            set: { val in
                guard let si = sections.firstIndex(where: { $0.id == sid }),
                      let li = sections[si].lectures.firstIndex(where: { $0.id == lid })
                else { return }
                sections[si].lectures[li][keyPath: keyPath] = val
            }
        )
    }

    @ViewBuilder
    private var errorSection: some View {
        if let err = errorMessage {
            SwiftUI.Section {
                Text(err).foregroundStyle(.red).font(.caption)
            }
        }
    }

    private func submitCourse() async {
        isSubmitting = true
        errorMessage = nil

        let sectionRequests = sections.map { s in
            SectionCreateRequest(
                title: s.title,
                lectures: s.lectures.map { l in
                    LectureCreateRequest(title: l.title, videoUrl: l.videoUrl, playTime: Int(l.playTimeStr) ?? 0)
                }
            )
        }

        let request = TeacherCourseRequest(
            title: title,
            description: courseDescription,
            category: category,
            level: level,
            price: nil,
            thumbnailUrl: thumbnailUrl.isEmpty ? nil : thumbnailUrl,
            sections: sectionRequests.isEmpty ? nil : sectionRequests
        )

        do {
            let result = try await APIService.shared.createTeacherCourse(request)

            // 이미지가 선택된 경우 썸네일 업로드
            if let imageData = thumbnailData, let courseId = result["courseId"] as? Int {
                _ = try await APIService.shared.uploadCourseThumbnail(courseId: courseId, imageData: imageData)
            }

            await onCreated()
            dismiss()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "강의 등록에 실패했습니다."
        }
        isSubmitting = false
    }
}

// MARK: - 강의 상세 관리 (수정/삭제 + 수강생 대시보드)

struct TeacherCourseDetailView: View {
    let courseId: Int
    let onUpdate: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var course: CourseDetail?
    @State private var dashboard: CourseDashboard?
    @State private var isLoading = true
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // 탭
            Picker("", selection: $selectedTab) {
                Text("커리큘럼").tag(0)
                Text("수강생").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                switch selectedTab {
                case 0:
                    curriculumTab
                case 1:
                    studentsTab
                default:
                    EmptyView()
                }
            }
        }
        .navigationTitle(course?.title ?? "강의 관리")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditSheet = true } label: {
                        Label("수정", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task { await loadDetail() }
        .alert("강의 삭제", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                Task { await deleteCourse() }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 강의를 삭제하시겠습니까?\n수강생 데이터도 모두 삭제됩니다.")
        }
        .sheet(isPresented: $showEditSheet) {
            if let c = course {
                CourseEditView(course: c, onSaved: { await loadDetail(); await onUpdate() })
            }
        }
    }

    // MARK: - 커리큘럼 탭

    private var curriculumTab: some View {
        ScrollView {
            if let course = course {
                VStack(alignment: .leading, spacing: 16) {
                    // 강의 정보
                    VStack(alignment: .leading, spacing: 8) {
                        if let desc = course.description {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            if let cat = course.category { Text(cat).font(.caption).padding(.horizontal, 8).padding(.vertical, 3).background(Color.mainCoral.opacity(0.12)).foregroundStyle(Color.mainCoral).cornerRadius(4) }
                            if let lev = course.level { Text(lev).font(.caption).padding(.horizontal, 8).padding(.vertical, 3).background(.orange.opacity(0.1)).foregroundStyle(.orange).cornerRadius(4) }
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // 섹션/레슨 목록
                    ForEach(course.sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title)
                                .font(.headline)
                                .padding(.horizontal)

                            if let lectures = section.lectures {
                                ForEach(lectures) { lecture in
                                    NavigationLink(destination: VideoPlayerView(
                                        lecture: lecture,
                                        courseTitle: course.title,
                                        allLectures: course.sections.flatMap { $0.lectures ?? [] }
                                    )) {
                                        HStack(spacing: 10) {
                                            Image(systemName: "play.circle.fill")
                                                .foregroundStyle(Color.mainCoral)
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
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }

    // MARK: - 수강생 탭

    private var studentsTab: some View {
        ScrollView {
            if let dash = dashboard {
                VStack(alignment: .leading, spacing: 16) {
                    // 요약
                    HStack(spacing: 12) {
                        StatCard(title: "수강생", value: "\(dash.totalStudents)", icon: "person.2.fill")
                        StatCard(title: "총 레슨", value: "\(dash.totalLectures)", icon: "play.rectangle.fill")
                    }
                    .padding(.horizontal)

                    Divider().padding(.horizontal)

                    if dash.students.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.3")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("아직 수강생이 없습니다")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(dash.students) { student in
                            HStack(spacing: 12) {
                                CircularProgressView(
                                    progress: student.progressPercent / 100.0,
                                    lineWidth: 4
                                )
                                .frame(width: 40, height: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(student.fullName)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(student.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(Int(student.progressPercent))%")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color.mainCoral)
                                    Text("\(student.completedLectures)/\(student.totalLectures)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }

    private func loadDetail() async {
        isLoading = true
        do {
            async let courseTask = APIService.shared.getCourseDetail(courseId: courseId)
            async let dashTask = APIService.shared.getCourseDashboard(courseId: courseId)
            course = try await courseTask
            dashboard = try await dashTask
        } catch {
            // 에러 처리
        }
        isLoading = false
    }

    private func deleteCourse() async {
        do {
            try await APIService.shared.deleteTeacherCourse(courseId: courseId)
            await onUpdate()
            dismiss()
        } catch {
            // 에러 처리
        }
    }
}

// MARK: - 강의 수정 화면

struct CourseEditView: View {
    let course: CourseDetail
    let onSaved: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var courseDescription: String
    @State private var category: String
    @State private var level: String
    @State private var thumbnailUrl: String
    @State private var isSaving = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var thumbnailData: Data?
    @State private var thumbnailImage: Image?
    @State private var editSections: [EditSectionItem] = []
    @State private var errorMessage: String?

    let categories = ["PORTRAIT", "LANDSCAPE", "FOOD", "STREET", "MACRO"]
    let levels = ["BEGINNER", "INTERMEDIATE", "ADVANCED"]

    init(course: CourseDetail, onSaved: @escaping () async -> Void) {
        self.course = course
        self.onSaved = onSaved
        _title = State(initialValue: course.title)
        _courseDescription = State(initialValue: course.description ?? "")
        _category = State(initialValue: course.category ?? "PORTRAIT")
        _level = State(initialValue: course.level ?? "BEGINNER")
        _thumbnailUrl = State(initialValue: course.thumbnailUrl ?? "")
        // 기존 섹션/레슨을 편집용 모델로 변환
        _editSections = State(initialValue: course.sections.map { section in
            EditSectionItem(
                existingId: section.sectionId,
                title: section.title,
                lectures: (section.lectures ?? []).map { lec in
                    EditLectureItem(
                        existingId: lec.lectureId,
                        title: lec.title,
                        videoUrl: lec.videoUrl ?? "",
                        playTime: lec.playTime
                    )
                }
            )
        })
    }

    var body: some View {
        NavigationStack {
            Form {
                courseInfoSection
                thumbnailSection
                sectionsEditSection
                if let err = errorMessage {
                    SwiftUI.Section {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("강의 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task { await save() }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }

    private var courseInfoSection: some View {
        SwiftUI.Section("강의 정보") {
            TextField("강의 제목", text: $title)
            TextField("강의 설명", text: $courseDescription, axis: .vertical)
                .lineLimit(3...6)
            Picker("카테고리", selection: $category) {
                ForEach(categories, id: \.self) { Text($0) }
            }
            Picker("레벨", selection: $level) {
                ForEach(levels, id: \.self) { Text($0) }
            }
        }
    }

    private var thumbnailSection: some View {
        SwiftUI.Section("썸네일 이미지") {
            if let thumbnailImage {
                thumbnailImage
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else if let urlStr = APIService.shared.fullImageURL(thumbnailUrl), let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color(.systemGray5))
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label(thumbnailData == nil ? "이미지 변경" : "다른 이미지 선택", systemImage: "photo.on.rectangle.angled")
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data),
                       let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                        thumbnailData = jpegData
                        thumbnailImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }

    private var sectionsEditSection: some View {
        SwiftUI.Section {
            ForEach($editSections) { $section in
                VStack(alignment: .leading, spacing: 8) {
                    // 섹션 헤더
                    HStack {
                        TextField("섹션 제목", text: $section.title)
                            .font(.headline)
                        Button(role: .destructive) {
                            editSections.removeAll { $0.id == section.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }

                    // 레슨 목록
                    ForEach($section.lectures) { $lecture in
                        VStack(spacing: 6) {
                            TextField("레슨 제목", text: $lecture.title)
                                .font(.subheadline)
                            HStack {
                                TextField("유튜브 URL", text: $lecture.videoUrl)
                                    .textInputAutocapitalization(.never)
                                    .font(.caption)

                                if !lecture.videoUrl.isEmpty, LectureRowView2.ytId(lecture.videoUrl) != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                }

                                TextField("시간(초)", value: $lecture.playTime, format: .number)
                                    .keyboardType(.numberPad)
                                    .frame(width: 60)
                                    .font(.caption)

                                Button(role: .destructive) {
                                    section.lectures.removeAll { $0.id == lecture.id }
                                } label: {
                                    Image(systemName: "xmark.circle")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                            }

                            // 유튜브 썸네일 미리보기
                            if let videoId = LectureRowView2.ytId(lecture.videoUrl) {
                                AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoId)/mqdefault.jpg")) { phase in
                                    if case .success(let img) = phase {
                                        img.resizable().aspectRatio(16/9, contentMode: .fill)
                                    }
                                }
                                .frame(height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(.leading, 16)
                    }

                    // 레슨 추가 버튼
                    Button {
                        withAnimation(.none) {
                            section.lectures.append(EditLectureItem(existingId: nil, title: "", videoUrl: "", playTime: 600))
                        }
                    } label: {
                        Label("레슨 추가", systemImage: "plus.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .padding(.leading, 16)
                }
                .padding(.vertical, 4)
            }

            // 섹션 추가 버튼
            Button {
                editSections.append(EditSectionItem(existingId: nil, title: "", lectures: []))
            } label: {
                Label("섹션 추가", systemImage: "plus.rectangle.on.rectangle")
            }
            .buttonStyle(.borderless)
        } header: {
            Text("섹션 / 레슨")
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil

        do {
            // 1. 강의 기본 정보 수정
            let request = TeacherCourseRequest(
                title: title,
                description: courseDescription,
                category: category,
                level: level,
                price: course.price,
                thumbnailUrl: thumbnailData != nil ? nil : (thumbnailUrl.isEmpty ? nil : thumbnailUrl),
                sections: nil
            )
            try await APIService.shared.updateTeacherCourse(courseId: course.courseId, request)

            // 2. 썸네일 업로드
            if let imageData = thumbnailData {
                _ = try await APIService.shared.uploadCourseThumbnail(courseId: course.courseId, imageData: imageData)
            }

            // 3. 섹션/레슨 동기화
            let originalSectionIds = Set(course.sections.map { $0.sectionId })
            let editSectionIds = Set(editSections.compactMap { $0.existingId })

            // 삭제된 섹션
            for sectionId in originalSectionIds.subtracting(editSectionIds) {
                try await APIService.shared.deleteSection(sectionId: sectionId)
            }

            // 기존 섹션 수정 + 새 섹션 추가
            for editSection in editSections {
                if let sectionId = editSection.existingId {
                    // 기존 섹션 제목 수정
                    let originalSection = course.sections.first { $0.sectionId == sectionId }
                    if originalSection?.title != editSection.title {
                        try await APIService.shared.updateSection(sectionId: sectionId, title: editSection.title)
                    }

                    // 레슨 동기화
                    let originalLectureIds = Set((originalSection?.lectures ?? []).map { $0.lectureId })
                    let editLectureIds = Set(editSection.lectures.compactMap { $0.existingId })

                    // 삭제된 레슨
                    for lectureId in originalLectureIds.subtracting(editLectureIds) {
                        try await APIService.shared.deleteLecture(lectureId: lectureId)
                    }

                    // 기존 레슨 수정
                    for editLecture in editSection.lectures {
                        if let lectureId = editLecture.existingId {
                            let originalLecture = originalSection?.lectures?.first { $0.lectureId == lectureId }
                            if originalLecture?.title != editLecture.title ||
                               originalLecture?.videoUrl != editLecture.videoUrl ||
                               originalLecture?.playTime != editLecture.playTime {
                                try await APIService.shared.updateLecture(
                                    lectureId: lectureId,
                                    title: editLecture.title,
                                    videoUrl: editLecture.videoUrl,
                                    playTime: editLecture.playTime
                                )
                            }
                        } else {
                            // 새 레슨 추가
                            try await APIService.shared.addLecture(
                                sectionId: sectionId,
                                title: editLecture.title,
                                videoUrl: editLecture.videoUrl,
                                playTime: editLecture.playTime
                            )
                        }
                    }
                } else {
                    // 새 섹션 추가
                    try await APIService.shared.addSection(courseId: course.courseId, title: editSection.title)
                    // 새 섹션에 레슨 추가는 섹션 ID를 알아야 하므로, 리로드 후 처리
                    // 현재는 섹션만 추가하고, 레슨은 다시 수정 화면에서 추가하도록 함
                }
            }

            await onSaved()
            dismiss()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "저장에 실패했습니다."
        }
        isSaving = false
    }
}

// MARK: - 수정용 모델

struct EditSectionItem: Identifiable {
    let id = UUID()
    var existingId: Int?
    var title: String
    var lectures: [EditLectureItem]
}

struct EditLectureItem: Identifiable {
    let id = UUID()
    var existingId: Int?
    var title: String
    var videoUrl: String
    var playTime: Int
}

// MARK: - Input Models

struct SectionInput: Identifiable {
    let id = UUID()
    var title = ""
    var lectures: [LectureInput] = []
}

struct LectureInput: Identifiable {
    let id = UUID()
    var title = ""
    var videoUrl = ""
    var playTimeStr = "600"
}

// MARK: - 레슨 행 (바인딩 체인 없음 — 부모가 직접 관리)

struct LectureRowView2: View {
    let lecture: LectureInput
    let titleBinding: Binding<String>
    let urlBinding: Binding<String>
    let playTimeBinding: Binding<String>
    var onDelete: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            TextField("레슨 제목", text: titleBinding)
                .font(.subheadline)

            HStack {
                TextField("유튜브 URL", text: urlBinding)
                    .textInputAutocapitalization(.never)
                    .font(.caption)

                if !lecture.videoUrl.isEmpty, Self.ytId(lecture.videoUrl) != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }

                TextField("시간(초)", text: playTimeBinding)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                    .font(.caption)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "xmark.circle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            if let videoId = Self.ytId(lecture.videoUrl) {
                AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoId)/mqdefault.jpg")) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(16/9, contentMode: .fill)
                    }
                }
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.leading, 16)
    }

    static func ytId(_ urlString: String) -> String? {
        guard !urlString.isEmpty else { return nil }
        if let components = URLComponents(string: urlString),
           let v = components.queryItems?.first(where: { $0.name == "v" })?.value {
            return v
        }
        if urlString.contains("youtu.be/"),
           let last = urlString.split(separator: "/").last {
            return String(last.split(separator: "?").first ?? last)
        }
        if urlString.contains("/embed/"),
           let v = urlString.split(separator: "/").last?.split(separator: "?").first {
            return String(v)
        }
        return nil
    }
}
