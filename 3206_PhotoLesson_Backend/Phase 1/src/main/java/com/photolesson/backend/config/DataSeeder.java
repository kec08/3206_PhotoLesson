package com.photolesson.backend.config;

import com.photolesson.backend.entity.*;
import com.photolesson.backend.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {

    private final CourseRepository courseRepository;
    private final SectionRepository sectionRepository;
    private final LectureRepository lectureRepository;
    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        // 기존 데이터가 있으면 건너뛰기 (유튜브 URL 업데이트 시 DB 초기화 필요)
        if (courseRepository.count() > 0) {
            log.info("데이터가 이미 존재합니다. 시드 데이터를 건너뜁니다. (유튜브 URL 업데이트 시 DB를 초기화해주세요)");
            return;
        }

        log.info("시드 데이터를 삽입합니다...");

        // Create admin/instructor member
        Member instructor = memberRepository.save(Member.builder()
                .email("admin@photolesson.com")
                .password(passwordEncoder.encode("admin1234"))
                .fullName("관리자")
                .role("INSTRUCTOR")
                .build());

        // === Course 1: 인물 사진 기초 ===
        Course course1 = courseRepository.save(Course.builder()
                .title("인물 사진 촬영의 기초")
                .description("인물 사진 촬영에 필요한 기본적인 기술과 노하우를 배우는 강좌입니다. 조명, 포즈, 구도 등 핵심 요소를 학습합니다.")
                .category("PORTRAIT")
                .level("BEGINNER")
                .price(55000)
                .instructorName("관리자")
                .thumbnailUrl("https://picsum.photos/seed/portrait/400/300")
                .build());

        Section s1_1 = sectionRepository.save(Section.builder()
                .course(course1).title("인물 사진 입문").sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s1_1).title("인물 사진이란?").videoUrl("https://www.youtube.com/watch?v=Qe3oJnFtA_k").playTime(600).sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s1_1).title("카메라 기본 설정").videoUrl("https://www.youtube.com/watch?v=V7z7BAZdt2M").playTime(720).sortOrder(2).build());
        lectureRepository.save(Lecture.builder()
                .section(s1_1).title("렌즈 선택 가이드").videoUrl("https://www.youtube.com/watch?v=BKi6XKPJRwI").playTime(540).sortOrder(3).build());

        Section s1_2 = sectionRepository.save(Section.builder()
                .course(course1).title("조명과 빛").sortOrder(2).build());
        lectureRepository.save(Lecture.builder()
                .section(s1_2).title("자연광 활용법").videoUrl("https://www.youtube.com/watch?v=PDJLvF1DAUg").playTime(900).sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s1_2).title("스튜디오 조명 기초").videoUrl("https://www.youtube.com/watch?v=qxFDDMbSxLc").playTime(1080).sortOrder(2).build());

        Section s1_3 = sectionRepository.save(Section.builder()
                .course(course1).title("포즈와 구도").sortOrder(3).build());
        lectureRepository.save(Lecture.builder()
                .section(s1_3).title("기본 포즈 가이드").videoUrl("https://www.youtube.com/watch?v=kmi9TPQ57Mo").playTime(780).sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s1_3).title("구도의 원칙").videoUrl("https://www.youtube.com/watch?v=7ZVyNjKSr0M").playTime(660).sortOrder(2).build());

        // === Course 2: 풍경 사진 마스터 ===
        Course course2 = courseRepository.save(Course.builder()
                .title("풍경 사진 마스터 클래스")
                .description("아름다운 풍경 사진을 촬영하기 위한 고급 기법을 배웁니다. 골든아워, 장노출, HDR 등 다양한 기술을 다룹니다.")
                .category("LANDSCAPE")
                .level("INTERMEDIATE")
                .price(72000)
                .instructorName("관리자")
                .thumbnailUrl("https://picsum.photos/seed/landscape/400/300")
                .build());

        Section s2_1 = sectionRepository.save(Section.builder()
                .course(course2).title("풍경 사진 기본").sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s2_1).title("풍경 촬영 장비").videoUrl("https://www.youtube.com/watch?v=KnKL2XGQNeY").playTime(840).sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s2_1).title("삼각대 활용법").videoUrl("https://www.youtube.com/watch?v=0wT6T0TFfI0").playTime(600).sortOrder(2).build());

        Section s2_2 = sectionRepository.save(Section.builder()
                .course(course2).title("고급 촬영 기법").sortOrder(2).build());
        lectureRepository.save(Lecture.builder()
                .section(s2_2).title("골든아워 촬영").videoUrl("https://www.youtube.com/watch?v=0r6C3z3TEKw").playTime(960).sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s2_2).title("장노출 촬영").videoUrl("https://www.youtube.com/watch?v=Hznzah--fHA").playTime(1200).sortOrder(2).build());
        lectureRepository.save(Lecture.builder()
                .section(s2_2).title("HDR 사진 촬영").videoUrl("https://www.youtube.com/watch?v=yjIXWb4CFGM").playTime(900).sortOrder(3).build());

        Section s2_3 = sectionRepository.save(Section.builder()
                .course(course2).title("후보정").sortOrder(3).build());
        lectureRepository.save(Lecture.builder()
                .section(s2_3).title("Lightroom 풍경 보정").videoUrl("https://www.youtube.com/watch?v=5ET1MjnDBxE").playTime(1500).sortOrder(1).build());

        // === Course 3: 음식 사진 촬영 ===
        Course course3 = courseRepository.save(Course.builder()
                .title("매력적인 음식 사진 촬영법")
                .description("SNS에서 돋보이는 음식 사진을 촬영하는 방법을 배웁니다. 스타일링, 조명, 각도 등 실전 노하우를 전수합니다.")
                .category("FOOD")
                .level("BEGINNER")
                .price(45000)
                .instructorName("관리자")
                .thumbnailUrl("https://picsum.photos/seed/food/400/300")
                .build());

        Section s3_1 = sectionRepository.save(Section.builder()
                .course(course3).title("음식 사진 시작하기").sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s3_1).title("음식 사진의 매력").videoUrl("https://www.youtube.com/watch?v=GxqjrzAYf-8").playTime(480).sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s3_1).title("스마트폰으로 음식 촬영").videoUrl("https://www.youtube.com/watch?v=X3mGJBFnFxw").playTime(720).sortOrder(2).build());

        Section s3_2 = sectionRepository.save(Section.builder()
                .course(course3).title("스타일링과 소품").sortOrder(2).build());
        lectureRepository.save(Lecture.builder()
                .section(s3_2).title("음식 스타일링 기초").videoUrl("https://www.youtube.com/watch?v=JV5Qhp2e8Wo").playTime(840).sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s3_2).title("배경과 소품 활용").videoUrl("https://www.youtube.com/watch?v=k2akVNz1GzA").playTime(660).sortOrder(2).build());

        Section s3_3 = sectionRepository.save(Section.builder()
                .course(course3).title("촬영 실전").sortOrder(3).build());
        lectureRepository.save(Lecture.builder()
                .section(s3_3).title("탑뷰 촬영법").videoUrl("https://www.youtube.com/watch?v=rINM-Z57L_4").playTime(540).sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s3_3).title("45도 각도 촬영법").videoUrl("https://www.youtube.com/watch?v=CwDM4m4N_Cg").playTime(600).sortOrder(2).build());
        lectureRepository.save(Lecture.builder()
                .section(s3_3).title("색감 보정 팁").videoUrl("https://www.youtube.com/watch?v=1yPwl1XNr-k").playTime(780).sortOrder(3).build());

        // === Course 4: 거리 사진 ===
        Course course4 = courseRepository.save(Course.builder()
                .title("스트리트 포토그래피 완전 정복")
                .description("거리에서 만나는 순간을 포착하는 스트리트 포토그래피의 모든 것을 배웁니다.")
                .category("STREET")
                .level("INTERMEDIATE")
                .price(60000)
                .instructorName("관리자")
                .thumbnailUrl("https://picsum.photos/seed/street/400/300")
                .build());

        Section s4_1 = sectionRepository.save(Section.builder()
                .course(course4).title("스트리트 사진 이해").sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s4_1).title("스트리트 사진의 역사").videoUrl("https://www.youtube.com/watch?v=KairdW5z91I").playTime(900).sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s4_1).title("결정적 순간 포착").videoUrl("https://www.youtube.com/watch?v=AX8UvAs4mEE").playTime(720).sortOrder(2).build());

        Section s4_2 = sectionRepository.save(Section.builder()
                .course(course4).title("실전 촬영").sortOrder(2).build());
        lectureRepository.save(Lecture.builder()
                .section(s4_2).title("도심 촬영 테크닉").videoUrl("https://www.youtube.com/watch?v=JsVzaFq_FJo").playTime(1080).sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s4_2).title("야간 거리 촬영").videoUrl("https://www.youtube.com/watch?v=1l-qXqYAoHM").playTime(960).sortOrder(2).build());

        // === Course 5: 접사 사진 ===
        Course course5 = courseRepository.save(Course.builder()
                .title("매크로 사진의 세계")
                .description("작은 세상을 크게 담는 매크로 사진 촬영 기법을 상세히 배웁니다. 꽃, 곤충, 물방울 등 다양한 피사체를 다룹니다.")
                .category("MACRO")
                .level("ADVANCED")
                .price(85000)
                .instructorName("관리자")
                .thumbnailUrl("https://picsum.photos/seed/macro/400/300")
                .build());

        Section s5_1 = sectionRepository.save(Section.builder()
                .course(course5).title("매크로 장비").sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s5_1).title("매크로 렌즈 선택").videoUrl("https://www.youtube.com/watch?v=aZ5RQyfh_co").playTime(720).sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s5_1).title("접사 링과 익스텐션 튜브").videoUrl("https://www.youtube.com/watch?v=WVjBY3wmQ0o").playTime(600).sortOrder(2).build());

        Section s5_2 = sectionRepository.save(Section.builder()
                .course(course5).title("매크로 촬영 기법").sortOrder(2).build());
        lectureRepository.save(Lecture.builder()
                .section(s5_2).title("초점 스태킹").videoUrl("https://www.youtube.com/watch?v=3JC1_xytFBE").playTime(1200).sortOrder(1).build());
        lectureRepository.save(Lecture.builder()
                .section(s5_2).title("매크로 조명 테크닉").videoUrl("https://www.youtube.com/watch?v=Nx2qHIFt5FI").playTime(900).sortOrder(2).build());
        lectureRepository.save(Lecture.builder()
                .section(s5_2).title("물방울 사진 촬영").videoUrl("https://www.youtube.com/watch?v=Y6PF3hNgFew").playTime(1080).sortOrder(3).build());

        log.info("시드 데이터 삽입 완료! (강좌 5개, 관리자 계정 1개)");
    }
}
