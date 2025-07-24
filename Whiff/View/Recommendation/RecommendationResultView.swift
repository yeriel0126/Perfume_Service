import SwiftUI

struct RecommendationResultView: View {
    let project: ProjectModel
    @StateObject private var viewModel = RecommendationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        RecommendationContentView(
            project: project,
            recommendations: $viewModel.recommendations,
            onDismiss: { dismiss() }
        )
        .task {
            // project.recommendations가 이미 있으면 API 호출 안하고 바로 사용
            if !project.recommendations.isEmpty {
                print("✅ Using pre-loaded recommendations: \(project.recommendations.count) items")
                viewModel.recommendations = project.recommendations
            } else {
                print("🔄 Fetching recommendations from API for project: \(project.id)")
                do {
                    try await viewModel.getRecommendations(projectId: project.id)
                } catch {
                    print("❌ Error fetching recommendations: \(error)")
                }
            }
        }
    }
}

private struct RecommendationContentView: View {
    let project: ProjectModel
    @Binding var recommendations: [PerfumeRecommendation]
    let onDismiss: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProjectHeaderView(project: project, recommendationCount: recommendations.count)
                RecommendationListView(recommendations: recommendations)
            }
            .padding(.vertical)
        }
        .navigationTitle("추천 결과")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("완료", action: onDismiss)
            }
        }
    }
}

private struct ProjectHeaderView: View {
    let project: ProjectModel
    let recommendationCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name)
                .font(.title)
                .fontWeight(.bold)
            
            Text("추천된 향수 \(recommendationCount)개")
                .font(.subheadline)
                .foregroundColor(.whiffSecondaryText2)
        }
        .padding(.horizontal)
    }
}

private struct RecommendationListView: View {
    let recommendations: [PerfumeRecommendation]
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(recommendations) { recommendation in
                RecommendationCard(recommendation: recommendation)
                    .onTapGesture {
                        // TODO: 향수 상세 페이지로 이동
                    }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 추천 카드 컴포넌트
private struct RecommendationCard: View {
    let recommendation: PerfumeRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 향수 이미지
            AsyncImage(url: URL(string: recommendation.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.whiffSecondaryText2.opacity(0.2))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.whiffSecondaryText2)
                    )
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recommendation.name)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(2)
                    .foregroundColor(.whiffPrimaryText)
                
                Text(recommendation.brand)
                    .font(.caption)
                    .foregroundColor(.whiffSecondaryText2)
                
                if let score = recommendation.score {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.caption)
                        
                        Text("매치도 \(String(format: "%.1f", score * 100))%")
                            .font(.caption)
                            .foregroundColor(.pink)
                    }
                }
                
                // 감정 태그
                if let emotionTags = recommendation.emotionTags, !emotionTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(emotionTags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.whiffPrimary.opacity(0.1))
                                    .foregroundColor(.whiffPrimary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.whiffSectionBackground)
        .cornerRadius(16)
    }
}

struct RecommendationResultView_Previews: PreviewProvider {
    static var previews: some View {
        let dateFormatter = ISO8601DateFormatter()
        let now = dateFormatter.string(from: Date())
        
        return RecommendationResultView(project: ProjectModel(
            id: "1",
            name: "샘플 프로젝트",
            userId: "user1",
            preferences: [],
            recommendations: [],
            createdAt: dateFormatter.date(from: now)!,
            updatedAt: dateFormatter.date(from: now)!,
            tags: ["sample"],
            isFavorite: false
        ))
    }
} 
