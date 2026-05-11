import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                MainTabView()
                    .transition(.move(edge: .trailing))
            } else {
                LoginView()
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: authManager.isLoggedIn)
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        TabView {
            // 홈 — 전체
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }

            // 내 강의 — 학생만
            if authManager.isStudent {
                MyCoursesView()
                    .tabItem {
                        Label("내 강의", systemImage: "play.rectangle.fill")
                    }
            }

            // 내 회원 — 강사만 (관리자 제외)
            if authManager.currentRole == "TEACHER" {
                TeacherStudentsView()
                    .tabItem {
                        Label("내 회원", systemImage: "person.2.fill")
                    }
            }

            // 포트폴리오 — 학생만
            if authManager.isStudent {
                PortfolioListView()
                    .tabItem {
                        Label("포트폴리오", systemImage: "photo.stack")
                    }
            }

            // 강의 관리 — 강사
            if authManager.currentRole == "TEACHER" {
                TeacherCourseView()
                    .tabItem {
                        Label("강의 관리", systemImage: "square.and.pencil")
                    }
            }

            // 강의 관리 — 관리자 (전체 강의)
            if authManager.isAdmin {
                AdminCourseView()
                    .tabItem {
                        Label("강의 관리", systemImage: "square.and.pencil")
                    }
            }

            // 유저 관리 — 관리자만
            if authManager.isAdmin {
                AdminUserListView()
                    .tabItem {
                        Label("유저 관리", systemImage: "person.3.fill")
                    }
            }

            // 마이페이지 — 전체
            MyPageView()
                .tabItem {
                    Label("마이페이지", systemImage: "person.fill")
                }
        }
        .tint(.mainCoral)
    }
}

#Preview("로그인 전") {
    ContentView()
        .environmentObject(AuthManager())
}

#Preview("메인 탭") {
    MainTabView()
        .environmentObject(AuthManager())
}
