# PhotoLesson 구현 체크리스트

## Phase 1 (완료)

### Auth
- [x] 회원가입 (POST /auth/signup)
- [x] 로그인 (POST /auth/login)
- [x] JWT 토큰 재발급 (POST /auth/refresh)
- [x] JWT role 추출 → 탭 분기
- [x] 자동 로그아웃 (토큰 만료 시)

### User
- [x] 유저 조회 (GET /users/{id})
- [x] 유저 정보 수정 (PUT /users/{id})
- [x] 관리자 유저 목록 (GET /admin/users)
- [x] 관리자 역할 변경 (PATCH /admin/users/{id}/role)

### Course
- [x] 강의 목록 페이징 (GET /courses)
- [x] 강의 상세 (GET /courses/{id})
- [x] 카테고리 필터
- [x] 강의 검색 (GET /courses/search)
- [x] 섹션/강의 계층 조회
- [x] 강의 상세 → 커리큘럼 표시

### Enrollment
- [x] 수강 신청 (POST /enrollments)
- [x] 수강 목록 조회 (GET /users/{id}/enrollments)
- [x] 수강 진도 조회 (GET /users/{id}/progress)
- [x] 수강 신청 성공 오버레이 UI

### Lecture / Video
- [x] 유튜브 플레이어 (WKWebView iframe)
- [x] 시청 완료 기록 (POST /lectures/{id}/watch-history)
- [x] 시청 이력 조회 (GET /users/{id}/watch-history)
- [x] 미완료 강의 자동 재생
- [x] iPad 좌우 분할 레이아웃

### Comment
- [x] 댓글 목록 조회 (GET /lectures/{id}/comments)
- [x] 댓글 작성 (POST /lectures/{id}/comments)
- [x] 본인 댓글 삭제 (DELETE /comments/{id})
- [x] 댓글 빈 상태 EmptyState UI

### Portfolio
- [x] 포트폴리오 생성 (POST /portfolios)
- [x] 포트폴리오 목록 페이징 (GET /portfolios)
- [x] 포트폴리오 상세 (GET /portfolios/{id})
- [x] 이미지 업로드 multipart (POST /portfolios/{id}/images)
- [x] 이미지 삭제 (DELETE /portfolios/{id}/images/{imgId})
- [x] 인스타 피드 스타일 뷰

### Teacher
- [x] 강의 등록 화면 (POST /teacher/courses)
- [x] 섹션/강의 중첩 생성

### UI / 공통
- [x] 역할별 탭 분기 (STUDENT / TEACHER / ADMIN)
- [x] 로그인/로그아웃 전환 애니메이션
- [x] 카테고리 칩 UI
- [x] StatCard 학습 현황
- [x] Color+Extensions (mainCoral)
- [x] DataSeeder (강좌 5개 + admin 계정)

---

## Phase 2 (완료)

### 에러 핸들링 통합
- [x] APIError 메시지 통일 (message/error fallback)
- [x] 백엔드 ErrorResponse DTO 형식 통일
- [x] 네트워크 미연결 에러 처리

### 역할 접근 제어 보강
- [x] 역할 변경 후 currentUser 즉시 재fetch
- [x] 역할 변경 시 탭 구성 실시간 반영
- [x] AdminUserListView 실제 API 연동

### 포트폴리오 무한 스크롤
- [x] PortfolioListView 무한 스크롤 (onAppear 트리거)
- [x] isLoadingMore 중복 요청 차단
- [x] totalPages 기반 마지막 페이지 판단

### 강의 검색 개선
- [x] HomeView 검색 debounce 0.5초 (Task.sleep)
- [x] 이전 검색 Task cancel 처리
- [x] 검색 결과 EmptyState UI
- [x] 최근 검색어 저장 (UserDefaults, 최대 10개)

### 프로필 이미지 업로드
- [x] MyPageView PhotosPicker 연동
- [x] HEIC → JPEG 변환 (jpegData 0.8)
- [x] 백엔드 POST /users/{id}/profile-image 엔드포인트
- [x] 기존 이미지 교체 시 서버 파일 삭제
- [x] 업로드 후 프로필 즉시 반영

### 수강 진도율 시각화
- [x] CircularProgressView 원형 그래프 컴포넌트
- [x] MyCoursesView 진도율 카드에 원형 그래프 추가
- [x] VideoPlayerView 학습통계 탭 구현 (레슨별 완료 현황)

### 코드 정리
- [x] print 디버그 로그 제거
- [x] 불필요 주석 정리

### 강사 기능 강화
- [x] 강의 생성 iOS → 백엔드 API 실제 연동 (CourseCreateView)
- [x] 섹션/레슨 동적 추가 UI (강의 등록 화면)
- [x] 내 강의 목록 조회 (GET /teacher/courses)
- [x] 강의 수정 (PUT /teacher/courses/{id}) + CourseEditView
- [x] 강의 삭제 (DELETE /teacher/courses/{id})
- [x] 섹션 추가/수정/삭제 API (POST/PUT/DELETE)
- [x] 레슨 추가/수정/삭제 API (POST/PUT/DELETE)
- [x] 수강생 현황 대시보드 (GET /teacher/dashboard, /courses/{id}/dashboard)
