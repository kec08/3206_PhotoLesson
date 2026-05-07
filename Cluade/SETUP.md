# PhotoLesson Phase 1 - 개발 환경 설정 가이드

## 프로젝트 구조

```
PhotoLesson/
├── 3206_PhotoLesson_Backend/   # Spring Boot 백엔드
│   └── Phase 1/
├── 3206_PhotoLesson_iOS/       # SwiftUI iOS 앱
│   └── Phase 1/
└── PhotoLesson_P1_기획서.pages
```

---

## 1. 사전 요구사항

### 백엔드
- **Java 17** 이상 (Java 21도 호환)
- **MySQL 8.x**
- **Gradle 8.x** (프로젝트에 Gradle Wrapper 포함되어 있음)
- **IntelliJ IDEA** (권장) 또는 터미널

### iOS
- **macOS** (Xcode 실행 필수)
- **Xcode 15** 이상
- **iOS 17** 이상 시뮬레이터 또는 실기기

---

## 2. 백엔드 설정 및 실행

### 2-1. MySQL 데이터베이스 생성

```sql
mysql -u root -p
CREATE DATABASE photolesson;
```

### 2-2. application.yml 수정

파일 위치: `3206_PhotoLesson_Backend/Phase 1/src/main/resources/application.yml`

**본인 MySQL 계정 정보로 수정:**

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/photolesson?useSSL=false&serverTimezone=Asia/Seoul&allowPublicKeyRetrieval=true
    username: root          # ← 본인 MySQL 유저명
    password: 1234          # ← 본인 MySQL 비밀번호
```

> 나머지 설정(JWT, 포트 등)은 변경하지 않아도 됩니다.

### 2-3. 서버 실행

```bash
cd 3206_PhotoLesson_Backend/Phase\ 1
./gradlew bootRun
```

또는 IntelliJ에서:
1. 프로젝트 열기 → `Phase 1` 폴더
2. 우측 Gradle 패널 → `Tasks` → `application` → `bootRun` 더블클릭

### 2-4. 실행 확인

서버 시작 시 다음 로그가 나오면 성공:

```
시드 데이터를 삽입합니다...
시드 데이터 삽입 완료! (강좌 5개, 관리자 계정 1개)
```

- 서버 주소: `http://localhost:8080`
- 테이블 자동 생성 (`ddl-auto: update`)
- 초기 데이터 자동 시딩 (강좌 5개 + 관리자 계정)

### 2-5. 시드 관리자 계정

| 항목 | 값 |
|------|-----|
| 이메일 | admin@photolesson.com |
| 비밀번호 | admin1234 |
| 역할 | INSTRUCTOR |

---

## 3. iOS 설정 및 실행

### 3-1. 프로젝트 열기

Xcode에서 `3206_PhotoLesson_iOS/Phase 1/3206_PhotoLesson.xcodeproj` 열기

### 3-2. 서버 주소 변경 (중요!)

파일 위치: `Phase 1/3206_PhotoLesson/Services/APIService.swift`

```swift
private let serverHost = "http://172.28.15.240:8080"  // ← 본인 Mac IP로 변경
```

**본인 Mac IP 확인 방법:**

```bash
ipconfig getifaddr en0
```

> 시뮬레이터 사용 시 `http://localhost:8080`으로도 가능하지만,
> 실기기 테스트 시에는 반드시 Mac의 실제 IP 주소를 사용해야 합니다.

### 3-3. ATS 설정 확인

Xcode → 프로젝트 → Info 탭에서 다음 설정이 있는지 확인:

```
App Transport Security Settings
  └── Allow Arbitrary Loads → YES
```

> `http://` 연결을 허용하기 위한 설정입니다. 이 설정이 없으면 서버 연결이 차단됩니다.

### 3-4. 빌드 및 실행

1. Xcode에서 시뮬레이터 또는 실기기 선택
2. `Cmd + R`로 빌드 및 실행
3. **백엔드 서버가 실행 중인 상태에서** iOS 앱을 실행해야 합니다

---

## 4. 주요 API 엔드포인트

| 구분 | 메서드 | 경로 | 인증 |
|------|--------|------|------|
| 회원가입 | POST | /api/v1/auth/signup | 불필요 |
| 로그인 | POST | /api/v1/auth/login | 불필요 |
| 토큰 재발급 | POST | /api/v1/auth/refresh | 필요 |
| 사용자 조회 | GET | /api/v1/users/{userId} | 필요 |
| 사용자 수정 | PUT | /api/v1/users/{userId} | 필요 |
| 강의 목록 | GET | /api/v1/courses | 불필요 |
| 강의 상세 | GET | /api/v1/courses/{courseId} | 불필요 |
| 강의 검색 | GET | /api/v1/courses/search | 불필요 |
| 수강 신청 | POST | /api/v1/enrollments | 필요 |
| 진도율 조회 | GET | /api/v1/users/{userId}/progress | 필요 |
| 시청 이력 기록 | POST | /api/v1/lectures/{lectureId}/watch-history | 필요 |
| 시청 이력 조회 | GET | /api/v1/users/{userId}/watch-history | 필요 |
| 포트폴리오 생성 | POST | /api/v1/portfolios | 필요 |
| 포트폴리오 목록 | GET | /api/v1/portfolios | 필요 |
| 이미지 업로드 | POST | /api/v1/portfolios/{id}/images | 필요 |
| 이미지 삭제 | DELETE | /api/v1/portfolios/{id}/images/{imageId} | 필요 |

---

## 5. 기술 스택

### 백엔드
- Spring Boot 3.2.5
- Java 17
- Spring Data JPA + MySQL
- Spring Security + JWT (jjwt 0.12.5)
- Gradle (Kotlin DSL)
- Lombok

### iOS
- SwiftUI (iOS 17+)
- Swift 5.9+
- WebKit (유튜브 영상 재생)
- PhotosUI (이미지 업로드)

---

## 6. 트러블슈팅

### 백엔드 실행 시 포트 충돌

```
Web server failed to start. Port 8080 was already in use.
```

해결:
```bash
lsof -ti:8080 | xargs kill -9
```

### iOS에서 서버 연결 실패

1. 백엔드 서버가 실행 중인지 확인
2. `APIService.swift`의 `serverHost`가 올바른 IP인지 확인
3. ATS 설정(`Allow Arbitrary Loads = YES`)이 되어 있는지 확인
4. Mac과 iPhone이 같은 Wi-Fi에 연결되어 있는지 확인 (실기기)

### DB 초기화 (데이터 리셋)

```sql
mysql -u root -p -e "DROP DATABASE photolesson; CREATE DATABASE photolesson;"
```

서버 재시작하면 시드 데이터가 새로 생성됩니다.
