# PhotoLesson

사진 촬영 교육 플랫폼 (강의 수강 + 포트폴리오 관리)

## 구조

```
PhotoLesson/
├── 3206_PhotoLesson_Backend/Phase 1/   # Spring Boot
├── 3206_PhotoLesson_iOS/Phase 1/       # SwiftUI
├── Cluade/
│   ├── API_SPEC.md                     # 전체 API 명세
│   ├── CHECKLIST.md                    # P1/P2 구현 체크리스트
│   ├── CHECKLIST_P2.md                 # P2 강사/학생 분리 체크리스트
│   ├── DESIGN_P2.md                    # P2 설계 문서
│   ├── TEST_P2.md                      # P2 테스트 시나리오 + 결과
│   ├── SETUP.md                        # 환경 설정
│   └── SKILL.md                        # 프로젝트 보고 스킬
└── CLAUDE.md
```

## 엔티티

| 엔티티 | 테이블 | 설명 |
|--------|--------|------|
| Member | members | 사용자 (STUDENT/TEACHER/ADMIN) |
| Course | courses | 강좌 → 1:N Section, N:1 Member(instructor) |
| Section | sections | 섹션 → 1:N Lecture |
| Lecture | lectures | 개별 강의 (유튜브) |
| Enrollment | enrollments | 수강 등록 (Member ↔ Course) |
| LectureProgress | lecture_progress | 시청 이력/진도 |
| Portfolio | portfolios | 포트폴리오 → 1:N Image |
| PortfolioImage | portfolio_images | 첨부 이미지 |
| Comment | comments | 강의 댓글 |

## API

- Base: `/api/v1`
- 인증: JWT Bearer (Access + Refresh)
- 파일: multipart, 최대 10MB
- 에러 응답: `{ status, message, timestamp }` 통일
- 상세: `Cluade/API_SPEC.md` 참조

| 도메인 | prefix | 비고 |
|--------|--------|------|
| Auth | `/auth` | signup, login, refresh |
| User | `/users/{id}` | 조회, 수정, 프로필 이미지 업로드 |
| Course | `/courses` | 목록(페이징), 상세, 검색(debounce) |
| Section | `/courses/{id}/sections` | |
| Lecture | `/lectures/{id}` | 상세, watch-history |
| Enrollment | `/enrollments` | 신청, 진도 |
| Portfolio | `/portfolios` | CRUD, 이미지 업로드, 무한스크롤 |
| Comment | `/lectures/{id}/comments` | 작성, 삭제, 프로필 이미지 포함 |
| Teacher | `/teacher` | 강의 CRUD, 섹션/레슨 관리, 대시보드, 썸네일 |
| Admin | `/admin` | 유저 관리, 역할 변경 (ADMIN) |

## 백엔드

| 항목 | 값 |
|------|------|
| 패키지 | `com.photolesson.backend` |
| 레이어 | entity → repository → service → controller |
| DTO | `dto/{도메인}/` (Request/Response) |
| DB | MySQL 8, `ddl-auto: update` |
| 에러 처리 | `GlobalExceptionHandler` → `ErrorResponse` 통일 |
| 빌드 | `cd Phase\ 1 && ./gradlew bootRun` |

### Config

| 클래스 | 역할 |
|--------|------|
| SecurityConfig | CSRF off, JWT 필터, 권한 매핑 |
| JwtTokenProvider | 토큰 생성/검증 |
| JwtAuthenticationFilter | 요청별 토큰 파싱 |
| WebConfig | CORS 전체 허용 |
| DataSeeder | 시드 데이터 (강좌 5 + admin) |
| GlobalExceptionHandler | 에러 응답 통일 (P2) |

### 권한

| Path | STUDENT | TEACHER | ADMIN |
|------|---------|---------|-------|
| `/auth/**`, `GET /courses/**` | O | O | O |
| `/enrollments`, `/portfolios` | O(본인) | O | O |
| `/teacher/**` | X | O | O |
| `/admin/**` | X | X | O |

## iOS

| 항목 | 값 |
|------|------|
| 타겟 | iOS 17+ |
| 아키텍처 | SwiftUI + @EnvironmentObject |
| API | APIService.shared (싱글턴) |
| 서버주소 | `APIService.swift` → `serverHost` (ngrok URL) |
| 인증 | AuthManager.shared (JWT + UserDefaults) |

### 탭

| 탭 | View | 권한 |
|----|------|------|
| 홈 | HomeView | 전체 |
| 내 강의 | MyCoursesView | 로그인 |
| 포트폴리오 | PortfolioListView | 로그인 |
| 강의 관리 | TeacherCourseView | TEACHER+ |
| 유저 관리 | AdminUserListView | ADMIN |
| 마이페이지 | MyPageView | 로그인 |

### 디렉토리

```
3206_PhotoLesson/
├── Models/        # Codable 모델 (Course, User, Portfolio, Comment 등)
├── Views/
│   ├── Home/      # HomeView, CourseCardView, CategoryChip
│   ├── Course/    # CourseDetailView, VideoPlayerView, MyCoursesView, CommentSectionView, CircularProgressView
│   ├── Auth/      # LoginView, SignupView
│   ├── Portfolio/  # PortfolioListView, PortfolioDetailView, PortfolioFeedView
│   ├── Admin/     # AdminUserListView
│   ├── Teacher/   # TeacherCourseView
│   └── MyPage/    # MyPageView
├── Services/      # APIService, AuthManager
└── Extensions/    # Color+Extensions (mainCoral)
```

### 주요 컴포넌트

| View | 기능 |
|------|------|
| HomeView | 카테고리 칩 필터 + debounce 검색 + 최근 검색어 + LazyVGrid |
| CourseDetailView | 썸네일 + 커리큘럼 + 수강신청 |
| VideoPlayerView | YouTube iframe + 댓글 + 시청완료 + 학습통계 탭 |
| CoursePlayerView | 미완료 자동재생 + 재생목록 |
| CommentSectionView | 댓글 CRUD + EmptyState + 프로필 이미지 |
| CircularProgressView | 원형 진도율 그래프 컴포넌트 (P2) |
| PortfolioListView | 무한 스크롤 페이징 (P2) |
| PortfolioFeedView | 인스타 피드 스타일 이미지 슬라이더 |
| MyCoursesView | 수강 강의 + 원형 진도율 카드 |
| MyPageView | 프로필 이미지 업로드(PhotosPicker) + 진도율 + 포트폴리오 그리드 |
| TeacherCourseView | 강의 CRUD + 수강생 대시보드 |
| AdminUserListView | 유저 목록 + 역할 변경 (실시간 반영) |

## 실행

```bash
# 백엔드
cd 3206_PhotoLesson_Backend/Phase\ 1 && ./gradlew bootRun

# ngrok (외부 접속)
ngrok http 8080

# iOS
# Xcode → Phase 1/3206_PhotoLesson.xcodeproj → Cmd+R
# serverHost를 ngrok URL로 변경 필요
```

## 시드 계정

| email | password | role |
|-------|----------|------|
| admin@photolesson.com | admin1234 | ADMIN |
| teacher@photolesson.com | teacher1234 | TEACHER |
| student@photolesson.com | student1234 | STUDENT |

## 주의

- `application.yml` DB 비번, JWT secret 커밋 금지
- 실기기: `serverHost` → ngrok URL 또는 Mac IP 변경
- ATS: Info.plist에 `ngrok-free.dev`, `ngrok-free.app` 도메인 허용
- 이미지 URL: 서버 `/uploads/xxx.jpg` (상대경로) → 클라이언트에서 `{host}/uploads/xxx.jpg`로 변환

## Phase 진행

| Phase | 상태 | 내용 |
|-------|------|------|
| P1 | 완료 | Auth, Course, Enrollment, Portfolio, Comment, Teacher, Admin |
| P2 | 완료 | 에러 통합, 무한스크롤, 검색개선, 프로필이미지, 진도시각화, 강사 CRUD/대시보드, 코드 정리 |

### P2 주요 변경사항
- **에러 핸들링**: `GlobalExceptionHandler` → `{status, message, timestamp}` 통일
- **포트폴리오**: 무한 스크롤 (onAppear + isLoadingMore + totalPages)
- **검색**: debounce 0.5초, Task cancel, 최근 검색어 (UserDefaults, 최대 10개)
- **프로필 이미지**: PhotosPicker → HEIC→JPEG 변환 → multipart 업로드
- **진도 시각화**: CircularProgressView, MyCoursesView 진도 카드, VideoPlayerView 학습통계 탭
- **강사 기능**: 강의 CRUD, 섹션/레슨 개별 CRUD, 썸네일 업로드, 수강생 대시보드
- **역할 제어**: 역할 변경 후 currentUser 재fetch → 탭 구성 실시간 반영
- **코드 정리**: print 로그 제거, 임시 주석 제거
