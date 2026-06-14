import Foundation

enum SampleData {
    static let course1 = CourseListItem(
        courseId: 101,
        title: "DSLR 기초 - 노출 이해하기",
        category: "PORTRAIT",
        level: "BEGINNER",
        instructorName: "김사진",
        thumbnailUrl: nil,
        price: 0,
        sectionCount: 8,
        lectureCount: 24,
        createdAt: "2026-03-01T10:00:00Z"
    )

    static let course2 = CourseListItem(
        courseId: 102,
        title: "인물 촬영 고급 기법",
        category: "PORTRAIT",
        level: "ADVANCED",
        instructorName: "박포토",
        thumbnailUrl: nil,
        price: 55000,
        sectionCount: 5,
        lectureCount: 18,
        createdAt: "2026-02-20T10:00:00Z"
    )

    static let course3 = CourseListItem(
        courseId: 103,
        title: "풍경 사진의 모든 것",
        category: "LANDSCAPE",
        level: "INTERMEDIATE",
        instructorName: "이풍경",
        thumbnailUrl: nil,
        price: 39000,
        sectionCount: 6,
        lectureCount: 20,
        createdAt: "2026-02-15T10:00:00Z"
    )

    static let courses = [course1, course2, course3]

    static let lecture1 = Lecture(
        lectureId: 301,
        title: "노출이란?",
        videoUrl: nil,
        playTime: 1200,
        sortOrder: 1
    )

    static let lecture2 = Lecture(
        lectureId: 302,
        title: "ISO 설정하기",
        videoUrl: nil,
        playTime: 1500,
        sortOrder: 2
    )

    static let lecture3 = Lecture(
        lectureId: 303,
        title: "셔터 스피드의 이해",
        videoUrl: nil,
        playTime: 900,
        sortOrder: 3
    )

    static let section1 = Section(
        sectionId: 201,
        title: "1. 카메라 기초",
        sortOrder: 1,
        lectures: [lecture1, lecture2, lecture3]
    )

    static let section2 = Section(
        sectionId: 202,
        title: "2. 조명과 빛",
        sortOrder: 2,
        lectures: [
            Lecture(lectureId: 304, title: "자연광 활용법", videoUrl: nil, playTime: 1100, sortOrder: 1),
            Lecture(lectureId: 305, title: "인공조명 기초", videoUrl: nil, playTime: 1300, sortOrder: 2)
        ]
    )

    static let courseDetail = CourseDetail(
        courseId: 101,
        title: "DSLR 기초 - 노출 이해하기",
        description: "DSLR 카메라의 기본적인 노출 설정을 배우는 강의입니다. 초보자도 쉽게 따라할 수 있도록 구성되어 있습니다.",
        category: "PORTRAIT",
        level: "BEGINNER",
        instructorName: "김사진",
        thumbnailUrl: nil,
        price: 0,
        sections: [section1, section2],
        userProgress: UserProgress(
            enrollmentId: 401,
            completedLectures: 3,
            totalLectures: 24,
            progressPercent: 12.5
        )
    )

    static let courseDetailNotEnrolled = CourseDetail(
        courseId: 102,
        title: "인물 촬영 고급 기법",
        description: "전문 포토그래퍼의 인물 촬영 노하우를 배워보세요.",
        category: "PORTRAIT",
        level: "ADVANCED",
        instructorName: "박포토",
        thumbnailUrl: nil,
        price: 55000,
        sections: [section1],
        userProgress: nil
    )

    static let enrolledCourse1 = EnrolledCourse(
        courseId: 101,
        title: "DSLR 기초 - 노출 이해하기",
        category: "PORTRAIT",
        level: "BEGINNER",
        thumbnailUrl: nil,
        totalLectures: 24,
        completedLectures: 3,
        progressPercent: 12.5,
        enrolledAt: "2026-03-01T10:00:00Z"
    )

    static let enrolledCourse2 = EnrolledCourse(
        courseId: 102,
        title: "인물 촬영 고급 기법",
        category: "PORTRAIT",
        level: "ADVANCED",
        thumbnailUrl: nil,
        totalLectures: 35,
        completedLectures: 12,
        progressPercent: 34.3,
        enrolledAt: "2026-02-20T10:00:00Z"
    )

    static let progressResponse = ProgressResponse(
        userId: 1001,
        progress: [enrolledCourse1, enrolledCourse2],
        totalCompletedLectures: 15,
        totalEnrolledCourses: 2,
        totalProgressPercent: 23.4
    )

    static let portfolio1 = Portfolio(
        portfolioId: 601,
        memberId: 1001,
        portfolioName: "인물 촬영 - 3월",
        description: "봄빛을 활용한 인물 촬영 연습",
        imageCount: 15,
        createdAt: "2026-03-09T10:00:00Z"
    )

    static let portfolio2 = Portfolio(
        portfolioId: 602,
        memberId: 1001,
        portfolioName: "풍경 촬영 - 여행",
        description: nil,
        imageCount: 23,
        createdAt: "2026-02-15T14:30:00Z"
    )

    static let portfolios = [portfolio1, portfolio2]

    static let portfolioImage1 = PortfolioImage(
        imageId: 701,
        portfolioId: 601,
        imageUrl: "https://picsum.photos/400/300",
        thumbnailUrl: "https://picsum.photos/200/150",
        uploadedAt: "2026-03-09T10:05:00Z"
    )
}
