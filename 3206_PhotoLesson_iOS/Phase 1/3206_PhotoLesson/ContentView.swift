import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
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
