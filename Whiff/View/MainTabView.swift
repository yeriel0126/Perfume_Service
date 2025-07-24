import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }
                .tag(0)

            ScentDiaryView(selectedTab: $selectedTab)
                .tabItem {
                    Label("시향 일기", systemImage: "book.fill")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("프로필", systemImage: "person.fill")
                }
                .tag(2)
        }
    }
} 