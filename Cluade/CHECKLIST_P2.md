# Phase 2 체크리스트 — 강사/학생 분리

## 강사 계정 흐름
- [x] 강사 테스트 계정 생성 (회원가입 → ADMIN이 TEACHER로 변경)
- [x] 강사 로그인 시 JWT에 role=TEACHER 포함 확인
- [x] iOS 탭 분기: TEACHER면 "강의 관리" 탭 노출

## 강사: 강의 생성
- [x] CourseCreateView → POST /teacher/courses 실제 연동 확인
- [x] 섹션/레슨 동적 추가 UI 동작 확인
- [x] 카테고리/레벨 Picker 동작
- [x] 썸네일 URL 입력 동작

## 강사: 내 강의 관리
- [x] GET /teacher/courses → 내 강의 목록만 조회 (강사 본인 것만)
- [x] 강의 상세 → 커리큘럼 표시
- [x] PUT /teacher/courses/{id} → 강의 수정
- [x] DELETE /teacher/courses/{id} → 강의 삭제

## 강사: 수강생 대시보드
- [x] GET /teacher/dashboard → 전체 통계 (강의수, 수강생수, 레슨수)
- [x] GET /teacher/courses/{id}/dashboard → 강의별 수강생 진도율

## 학생 흐름
- [x] 학생 로그인 시 "강의 관리" 탭 안 보임 (403 확인)
- [x] 강의 탐색 → 강사 강의 포함 노출
- [x] 수강신청 → 시청기록 → 진도율 반영
- [x] 강사 대시보드에 학생 진도 실시간 반영

## 테스트 계정 정보

| 역할 | 이메일 | 비밀번호 | 비고 |
|------|--------|----------|------|
| 관리자 | admin@photolesson.com | admin1234 | ADMIN, 역할 변경 가능 |
| 강사 | teacher@photolesson.com | teacher1234 | TEACHER, 강의 관리 가능 |
| 학생 | student@photolesson.com | student1234 | STUDENT, 수강만 가능 |
