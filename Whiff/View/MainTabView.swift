import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "archivebox.fill")
                }

            RecommendationsTabView()
                .tabItem {
                    Label("Recommend", systemImage: "sparkles")
                }
        }
    }
} 