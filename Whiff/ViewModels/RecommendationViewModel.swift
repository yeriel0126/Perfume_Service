import Foundation

@MainActor
class RecommendationViewModel: ObservableObject {
    @Published var recommendations: [PerfumeRecommendation] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let recommendationService = RecommendationService.shared
    
    func getRecommendations(projectId: String) async throws {
        isLoading = true
        error = nil
        
        do {
            recommendations = try await recommendationService.getRecommendations(projectId: projectId)
        } catch {
            self.error = error
            throw error
        }
        
        isLoading = false
    }
    
    func saveRecommendationHistory(
        userId: String,
        recommendationId: String,
        selectedPerfumeId: String
    ) {
        Task {
            do {
                try await recommendationService.saveRecommendationHistory(
                    userId: userId,
                    recommendationId: recommendationId,
                    selectedPerfumeId: selectedPerfumeId
                )
            } catch {
                self.error = error
            }
        }
    }
} 