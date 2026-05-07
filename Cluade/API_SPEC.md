# PhotoLesson API 명세서

> Base URL: `http://{host}:8080/api/v1`
> 인증: JWT Bearer Token (`Authorization: Bearer {accessToken}`)

---

## 1. Auth

| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| POST | `/auth/signup` | X | `SignupRequest` | `SignupResponse` | 201 |
| POST | `/auth/login` | X | `LoginRequest` | `LoginResponse` | 200 |
| POST | `/auth/refresh` | O (Refresh) | - | `LoginResponse` | 200 |

### SignupRequest
```json
{
  "email": "string",
  "password": "string",
  "fullName": "string"
}
```

### SignupResponse
```json
{
  "userId": 1,
  "email": "string",
  "fullName": "string",
  "createdAt": "2026-04-01T00:00:00"
}
```

### LoginRequest
```json
{
  "email": "string",
  "password": "string"
}
```

### LoginResponse
```json
{
  "accessToken": "string",
  "refreshToken": "string",
  "userId": 1,
  "email": "string",
  "expiresIn": 3600
}
```

---

## 2. User

| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| GET | `/users/{userId}` | O | - | `UserDto` | 200 |
| PUT | `/users/{userId}` | O | `UserUpdateRequest` | `UserDto` | 200 |

### UserDto
```json
{
  "userId": 1,
  "email": "string",
  "fullName": "string",
  "profileImageUrl": "string | null",
  "role": "STUDENT | TEACHER | ADMIN",
  "createdAt": "2026-04-01T00:00:00"
}
```

### UserUpdateRequest
```json
{
  "fullName": "string",
  "profileImageUrl": "string | null"
}
```

---

## 3. Course

| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| GET | `/courses` | X | Query: `category`, `page`, `size`, `sort` | `PageResponse<CourseListItemDto>` | 200 |
| GET | `/courses/{courseId}` | X | - | `CourseDetailDto` | 200 |
| GET | `/courses/search` | X | Query: `keyword`, `page`, `size` | `PageResponse<CourseListItemDto>` | 200 |

### CourseListItemDto
```json
{
  "courseId": 1,
  "title": "string",
  "category": "PORTRAIT | LANDSCAPE | FOOD | STREET | MACRO",
  "level": "BEGINNER | INTERMEDIATE | ADVANCED",
  "instructorName": "string",
  "thumbnailUrl": "string | null",
  "price": 0,
  "sectionCount": 3,
  "lectureCount": 10,
  "createdAt": "2026-04-01T00:00:00"
}
```

### CourseDetailDto
```json
{
  "courseId": 1,
  "title": "string",
  "description": "string",
  "category": "string",
  "level": "string",
  "instructorName": "string",
  "thumbnailUrl": "string | null",
  "price": 0,
  "sections": [SectionDto],
  "userProgress": {
    "enrollmentId": 1,
    "completedLectures": 5,
    "totalLectures": 10,
    "progressPercent": 50.0
  }
}
```

---

## 4. Section / Lecture

| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| GET | `/courses/{courseId}/sections` | O | - | `List<SectionDto>` | 200 |
| GET | `/sections/{sectionId}/lectures` | O | - | `List<LectureDto>` | 200 |
| GET | `/lectures/{lectureId}` | O | - | `LectureDetailDto` | 200 |

### SectionDto
```json
{
  "sectionId": 1,
  "title": "string",
  "sortOrder": 1,
  "lectures": [LectureDto]
}
```

### LectureDto
```json
{
  "lectureId": 1,
  "title": "string",
  "videoUrl": "string | null",
  "playTime": 300,
  "sortOrder": 1
}
```

### LectureDetailDto
```json
{
  "lectureId": 1,
  "title": "string",
  "videoUrl": "string | null",
  "playTime": 300,
  "sectionId": 1
}
```

---

## 5. Watch History

| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| POST | `/lectures/{lectureId}/watch-history` | O | `WatchHistoryRequest` | `WatchHistoryResponse` | 200 |
| GET | `/users/{userId}/watch-history` | O | - | `List<WatchHistoryResponse>` | 200 |

### WatchHistoryRequest
```json
{
  "lastPosition": 300
}
```

### WatchHistoryResponse
```json
{
  "progressId": 1,
  "lectureId": 1,
  "memberId": 1,
  "lastPosition": 300,
  "updatedAt": "2026-04-01T00:00:00"
}
```

---

## 6. Enrollment

| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| POST | `/enrollments` | O | `EnrollmentRequest` | `EnrollmentResponse` | 201 |
| GET | `/users/{userId}/enrollments` | O | - | `List<EnrollmentResponse>` | 200 |
| GET | `/users/{userId}/progress` | O | - | `ProgressResponseDto` | 200 |

### EnrollmentRequest
```json
{
  "courseId": 1
}
```

### EnrollmentResponse
```json
{
  "enrollmentId": 1,
  "memberId": 1,
  "courseId": 1,
  "enrolledAt": "2026-04-01T00:00:00",
  "isCompleted": false
}
```

### ProgressResponseDto
```json
{
  "userId": 1,
  "progress": [
    {
      "courseId": 1,
      "title": "string",
      "category": "string",
      "level": "string",
      "thumbnailUrl": "string | null",
      "totalLectures": 10,
      "completedLectures": 5,
      "progressPercent": 50.0,
      "enrolledAt": "2026-04-01T00:00:00"
    }
  ],
  "totalCompletedLectures": 15,
  "totalEnrolledCourses": 3,
  "totalProgressPercent": 60.0
}
```

---

## 7. Portfolio

| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| POST | `/portfolios` | O | `PortfolioCreateRequest` | `PortfolioDto` | 201 |
| GET | `/portfolios` | O | Query: `page`, `size` | `PageResponse<PortfolioDto>` | 200 |
| GET | `/portfolios/{id}` | O | - | `PortfolioDto` | 200 |
| GET | `/portfolios/{id}/images` | O | - | `List<PortfolioImageDto>` | 200 |
| POST | `/portfolios/{id}/images` | O | `MultipartFile(file)` | `PortfolioImageDto` | 201 |
| DELETE | `/portfolios/{id}/images/{imgId}` | O | - | - | 200 |

### PortfolioCreateRequest
```json
{
  "portfolioName": "string",
  "description": "string | null"
}
```

### PortfolioDto
```json
{
  "portfolioId": 1,
  "memberId": 1,
  "portfolioName": "string",
  "description": "string | null",
  "imageCount": 5,
  "createdAt": "2026-04-01T00:00:00"
}
```

### PortfolioImageDto
```json
{
  "imageId": 1,
  "portfolioId": 1,
  "imageUrl": "/uploads/xxx.jpg",
  "thumbnailUrl": "/uploads/thumb_xxx.jpg",
  "uploadedAt": "2026-04-01T00:00:00"
}
```

---

## 8. Comment

| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| POST | `/lectures/{lectureId}/comments` | O | `CommentCreateRequest` | `CommentDto` | 201 |
| GET | `/lectures/{lectureId}/comments` | O | - | `List<CommentDto>` | 200 |
| DELETE | `/comments/{commentId}` | O | - | - | 204 |

### CommentCreateRequest
```json
{
  "content": "string"
}
```

### CommentDto
```json
{
  "commentId": 1,
  "lectureId": 1,
  "memberId": 1,
  "memberName": "string",
  "content": "string",
  "createdAt": "2026-04-01T00:00:00"
}
```

---

## 9. Teacher (TEACHER / ADMIN 전용)

| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| POST | `/teacher/courses` | O (TEACHER+) | `CourseCreateRequest` | `{ courseId, title, message }` | 201 |

### CourseCreateRequest
```json
{
  "title": "string",
  "description": "string",
  "category": "PORTRAIT",
  "level": "BEGINNER",
  "thumbnailUrl": "string | null",
  "price": 0,
  "sections": [
    {
      "title": "string",
      "sortOrder": 1,
      "lectures": [
        {
          "title": "string",
          "videoUrl": "https://youtube.com/...",
          "playTime": 300,
          "sortOrder": 1
        }
      ]
    }
  ]
}
```

---

## 10. Admin (ADMIN 전용)

| Method | Path | Auth | Request | Response | Status |
|--------|------|------|---------|----------|--------|
| GET | `/admin/users` | O (ADMIN) | - | `List<UserDto>` | 200 |
| PATCH | `/admin/users/{userId}/role` | O (ADMIN) | `{ "role": "TEACHER" }` | `UserDto` | 200 |

---

## 공통

### PageResponse
```json
{
  "content": [T],
  "page": 0,
  "size": 10,
  "totalElements": 100,
  "totalPages": 10
}
```

### ErrorResponse
```json
{
  "status": 400,
  "message": "에러 메시지",
  "timestamp": "2026-04-01T00:00:00"
}
```

### 권한 매트릭스

| Path | STUDENT | TEACHER | ADMIN |
|------|---------|---------|-------|
| `/auth/**` | O | O | O |
| `GET /courses/**` | O | O | O |
| `GET /sections/**`, `GET /lectures/**` | O | O | O |
| `/enrollments`, `/users/{id}/**` | O (본인) | O | O |
| `/portfolios/**` | O (본인) | O | O |
| `/lectures/{id}/comments` | O | O | O |
| `/teacher/**` | X | O | O |
| `/admin/**` | X | X | O |

### 이미지 URL
- 서버 저장 경로: `/uploads/xxx.jpg` (상대 경로)
- 클라이언트 변환: `http://{host}:8080/uploads/xxx.jpg` (절대 경로)
- 업로드 최대: 10MB, `multipart/form-data`
