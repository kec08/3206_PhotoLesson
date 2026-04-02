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
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }

            MyCoursesView()
                .tabItem {
                    Label("내 강의", systemImage: "play.rectangle.fill")
                }

            PortfolioListView()
                .tabItem {
                    Label("포트폴리오", systemImage: "photo.stack")
                }

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
