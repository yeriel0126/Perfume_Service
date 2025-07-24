import SwiftUI

struct RecommendationsTabView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var selectedModel: RecommendationModelType = .standard
    @State private var showingModelInfo = false

    var body: some View {
        VStack(spacing: 24) {
            // 헤더
            HeaderSection()
            
            // 모델 선택 섹션
            ModelSelectionView(
                selectedModel: $selectedModel,
                projectStore: projectStore,
                showingModelInfo: $showingModelInfo
            )

            // 추천 시작 버튼
            StartRecommendationButton(
                selectedModel: selectedModel,
                projectStore: projectStore
            )

            Spacer()
        }
        .padding()
        .background(Color.whiffMainBackground)
        .task {
            await loadInitialData()
        }
        .sheet(isPresented: $showingModelInfo) {
            ModelInfoSheet(projectStore: projectStore)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() async {
        await projectStore.checkModelStatus()
        await projectStore.checkSystemHealth()
    }
}

// MARK: - Header Section

private struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("향수 추천")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.whiffPrimaryText)

            Text("새로운 프로젝트를 시작하고\n당신만의 시그니처 향을 찾아보세요")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.whiffSecondaryText2)
        }
    }
}

// MARK: - Start Recommendation Button

private struct StartRecommendationButton: View {
    let selectedModel: RecommendationModelType
    let projectStore: ProjectStore
    
    var body: some View {
        NavigationLink(destination:
            ProjectCreateView(selectedModel: selectedModel)
                .environmentObject(projectStore)
        ) {
            RecommendationStartButton(
                selectedModel: selectedModel,
                isModelHealthy: projectStore.isModelHealthy
            )
        }
        .disabled(!projectStore.isModelHealthy && selectedModel == .cluster)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        RecommendationsTabView()
            .environmentObject(ProjectStore())
    }
} 
