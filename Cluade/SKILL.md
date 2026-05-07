# PhotoLesson 프로젝트 보고 스킬

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 프로젝트명 | PhotoLesson |
| 분류 | 사진 촬영 교육 플랫폼 |
| 백엔드 | Spring Boot 3 + MySQL 8 + JWT |
| 프론트엔드 | SwiftUI (iOS 17+) |
| 아키텍처 | REST API + 싱글턴 서비스 + EnvironmentObject |

## 핵심 기능

### 학생 (STUDENT)
- 강의 탐색 (카테고리 필터, 검색)
- 수강 신청 / 강의 시청 (유튜브 임베드)
- 시청 진도 추적 (자동 재생, 완료 표시)
- 강의 댓글 작성/삭제
- 포트폴리오 생성 / 이미지 업로드
- 마이페이지 (학습 현황, 포트폴리오 그리드)

### 선생님 (TEACHER)
- 강의 등록 (섹션 > 강의 계층, 유튜브 URL)
- 학생 기능 전체 포함

### 관리자 (ADMIN)
- 유저 목록 조회 / 역할 변경
- 선생님 + 학생 기능 전체 포함

## 기술 스택

| 레이어 | 기술 |
|--------|------|
| 서버 | Spring Boot 3, Spring Security, JPA/Hibernate |
| DB | MySQL 8, ddl-auto: update |
| 인증 | JWT (Access + Refresh), BCrypt |
| iOS | SwiftUI, WKWebView (YouTube), Combine |
| 네트워크 | URLSession async/await, multipart 업로드 |
| 파일 | 서버 로컬 저장 (/uploads/), 최대 10MB |

## 개발 일정

| Phase | 기간 | 주요 작업 |
|-------|------|----------|
| P1 | ~4/15 | 전체 CRUD, JWT 인증, 유튜브 연동, 댓글, 포트폴리오, 역할 분기 |
| P2 | 4/16~ | 에러 통합, 무한스크롤, 검색 debounce, 프로필 이미지, 진도 시각화 |

## API 규모

| 도메인 | 엔드포인트 수 |
|--------|-------------|
| Auth | 3 |
| User | 2 |
| Course | 3 |
| Section/Lecture | 3 |
| Watch History | 2 |
| Enrollment | 3 |
| Portfolio | 6 |
| Comment | 3 |
| Teacher | 1 |
| Admin | 2 |
| **합계** | **28** |

## 참고 문서

| 파일 | 내용 |
|------|------|
| CLAUDE.md | 프로젝트 규칙, 구조, 실행 방법 |
| CHECKLIST.md | P1/P2 구현 체크리스트 |
| API_SPEC.md | 전체 API 명세 (Request/Response) |
