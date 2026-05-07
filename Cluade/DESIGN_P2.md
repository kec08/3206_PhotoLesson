# Phase 2 설계 문서 — PhotoLesson

> Phase 2 목표: UX 개선, 강사 기능 강화, 코드 품질 향상

---

## 1. 에러 핸들링 통합

### 목적
P1에서 API별로 산발적이던 에러 처리를 통일하여 사용자에게 일관된 에러 메시지를 제공한다.

### 설계

**백엔드**
- `GlobalExceptionHandler`에서 모든 예외를 `ErrorResponse` DTO로 통일
- 응답 형식: `{ status, message, timestamp }`
- 커스텀 예외: `BusinessException`, `UnauthorizedException`, `ResourceNotFoundException`

**iOS**
- `APIService`에서 서버 응답의 `message` 또는 `error` 필드를 파싱하여 `APIError.serverError(message)` 생성
- 네트워크 미연결 시 `URLError.notConnectedToInternet` → 별도 에러 메시지 표시

### 영향 범위
| 레이어 | 파일 |
|--------|------|
| Backend | `GlobalExceptionHandler.java`, `ErrorResponse.java`, 각 Service |
| iOS | `APIService.swift` (에러 파싱 로직) |

---

## 2. 역할 접근 제어 보강

### 목적
Admin이 역할을 변경했을 때 앱 UI가 즉시 반영되지 않는 문제를 해결한다.

### 설계

**역할 변경 → 즉시 반영 흐름:**
```
AdminUserListView → PATCH /admin/users/{id}/role
    → 성공 시 AuthManager.currentUser 재fetch
    → @Published 변경 → ContentView 탭 구성 재렌더링
```

- `AuthManager.fetchCurrentUser()`: GET /users/{id} 호출 → role 갱신
- `ContentView`: `authManager.currentUser?.role` 기반 탭 분기 (STUDENT: 4탭, TEACHER: 5탭, ADMIN: 6탭)
- `AdminUserListView`: 더미 데이터 제거 → GET /admin/users 실제 연동

### 영향 범위
| 레이어 | 파일 |
|--------|------|
| iOS | `AuthManager.swift`, `ContentView.swift`, `AdminUserListView.swift` |

---

## 3. 포트폴리오 무한 스크롤

### 목적
포트폴리오 목록에서 전체 데이터를 한 번에 로딩하지 않고, 스크롤 시 다음 페이지를 자동 로드한다.

### 설계

**페이징 전략:**
- 서버: GET /portfolios?page=0&size=10 (기존 PageResponse 활용)
- iOS: `onAppear`로 마지막 아이템 감지 → 다음 페이지 요청

**상태 관리:**
```swift
@Published var portfolios: [Portfolio] = []
@Published var isLoadingMore = false
private var currentPage = 0
private var totalPages = 1

func loadMore() {
    guard !isLoadingMore, currentPage < totalPages else { return }
    isLoadingMore = true
    // fetch page → append → currentPage += 1
}
```

**중복 요청 방지:** `isLoadingMore` 플래그로 동시 요청 차단

### 영향 범위
| 레이어 | 파일 |
|--------|------|
| iOS | `PortfolioListView.swift` |

---

## 4. 강의 검색 개선

### 목적
검색 입력 시 매 글자마다 API를 호출하는 문제를 해결하고, 검색 UX를 개선한다.

### 설계

**Debounce 검색:**
```swift
.onChange(of: searchText) { newValue in
    searchTask?.cancel()
    searchTask = Task {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        await performSearch(keyword: newValue)
    }
}
```

**최근 검색어:**
- `UserDefaults`에 최대 10개 저장
- 검색창 포커스 시 최근 검색어 목록 표시
- 검색어 탭 → 즉시 검색 실행

**검색 결과 없음:**
- EmptyState UI 표시 ("검색 결과가 없습니다")

### 영향 범위
| 레이어 | 파일 |
|--------|------|
| iOS | `HomeView.swift` |

---

## 5. 프로필 이미지 업로드

### 목적
사용자가 직접 프로필 사진을 설정할 수 있게 한다.

### 설계

**업로드 흐름:**
```
MyPageView → PhotosPicker (iOS 17)
    → 이미지 선택 → HEIC/PNG → JPEG 변환 (0.8 품질)
    → POST /users/{id}/profile-image (multipart/form-data)
    → 서버: /uploads/profile_{userId}.jpg 저장
    → 응답: profileImageUrl → AuthManager.currentUser 갱신
```

**백엔드 엔드포인트:**
| Method | Path | Request | Response |
|--------|------|---------|----------|
| POST | `/users/{userId}/profile-image` | `MultipartFile(file)` | `UserDto` |

**이미지 교체 정책:**
- 기존 이미지가 있으면 서버 파일 시스템에서 삭제 후 새 파일 저장
- 파일명: `profile_{userId}_{timestamp}.jpg`

### 영향 범위
| 레이어 | 파일 |
|--------|------|
| Backend | `UserController.java`, `UserService.java`, `FileService.java` |
| iOS | `MyPageView.swift`, `APIService.swift` |

---

## 6. 수강 진도율 시각화

### 목적
학생이 자신의 학습 진도를 시각적으로 확인할 수 있게 한다.

### 설계

**CircularProgressView 컴포넌트:**
```swift
struct CircularProgressView: View {
    let progress: Double  // 0.0 ~ 1.0
    // 원형 프로그레스 바 + 중앙 퍼센트 텍스트
}
```

**적용 위치:**
1. **MyCoursesView** — 각 수강 강의 카드에 원형 진도율 표시
2. **VideoPlayerView 학습통계 탭** — 해당 강의의 레슨별 완료 현황 리스트

**데이터 흐름:**
```
GET /users/{id}/progress → ProgressResponseDto
    → courseProgress.progressPercent → CircularProgressView
```

### 영향 범위
| 레이어 | 파일 |
|--------|------|
| iOS | `CircularProgressView.swift` (신규), `MyCoursesView.swift`, `VideoPlayerView.swift` |

---

## 7. 강사 기능 강화

### 목적
P1에서 강의 생성만 가능하던 강사 기능을 완전한 CRUD + 대시보드로 확장한다.

### 설계

**7-1. 강의 CRUD**

| 기능 | Method | Path | iOS View |
|------|--------|------|----------|
| 생성 | POST | `/teacher/courses` | CourseCreateView |
| 목록 | GET | `/teacher/courses` | TeacherCourseView |
| 수정 | PUT | `/teacher/courses/{id}` | CourseEditView |
| 삭제 | DELETE | `/teacher/courses/{id}` | TeacherCourseView (스와이프) |

**7-2. 섹션/레슨 개별 관리**

| 대상 | Method | Path |
|------|--------|------|
| 섹션 추가 | POST | `/teacher/courses/{id}/sections` |
| 섹션 수정 | PUT | `/teacher/sections/{id}` |
| 섹션 삭제 | DELETE | `/teacher/sections/{id}` |
| 레슨 추가 | POST | `/teacher/sections/{id}/lectures` |
| 레슨 수정 | PUT | `/teacher/lectures/{id}` |
| 레슨 삭제 | DELETE | `/teacher/lectures/{id}` |

**7-3. 수강생 대시보드**

| Method | Path | 응답 |
|--------|------|------|
| GET | `/teacher/dashboard` | 전체 통계 (강의수, 총 수강생수, 총 레슨수) |
| GET | `/teacher/courses/{id}/dashboard` | 강의별 수강생 목록 + 각 진도율 |

**대시보드 응답 DTO:**
```json
// GET /teacher/dashboard
{
  "totalCourses": 5,
  "totalStudents": 30,
  "totalLectures": 45
}

// GET /teacher/courses/{id}/dashboard
{
  "courseId": 1,
  "courseTitle": "인물 사진 기초",
  "students": [
    {
      "userId": 10,
      "fullName": "홍길동",
      "progressPercent": 75.0,
      "completedLectures": 6,
      "totalLectures": 8
    }
  ]
}
```

**강의 썸네일 업로드:**
| Method | Path | Request |
|--------|------|---------|
| POST | `/teacher/courses/{id}/thumbnail` | `MultipartFile(file)` |

### 영향 범위
| 레이어 | 파일 |
|--------|------|
| Backend | `TeacherController.java`, `TeacherService.java`, `SectionController.java`, `LectureController.java` |
| iOS | `TeacherCourseView.swift`, `CourseCreateView.swift`, `CourseEditView.swift`, `TeacherDashboardView.swift` |

---

## 8. 코드 정리

### 목적
디버깅용 코드를 제거하여 배포 준비 상태로 만든다.

### 작업 내용
- `print()` 디버그 로그 전수 제거
- 불필요 주석 (`// TODO`, `// test` 등) 정리
- 미사용 import 제거

---

## 엔티티 관계도 (P2 기준)

```
Member (STUDENT / TEACHER / ADMIN)
  ├── 1:N → Enrollment → N:1 → Course
  │                                ├── 1:N → Section → 1:N → Lecture
  │                                │                          └── 1:N → Comment
  │                                │                          └── 1:N → LectureProgress
  │                                └── N:1 → Member (instructor)
  └── 1:N → Portfolio → 1:N → PortfolioImage
```

---

## 테스트 계정

| 역할 | 이메일 | 비밀번호 |
|------|--------|----------|
| ADMIN | admin@photolesson.com | admin1234 |
| TEACHER | teacher@photolesson.com | teacher1234 |
| STUDENT | student@photolesson.com | student1234 |
