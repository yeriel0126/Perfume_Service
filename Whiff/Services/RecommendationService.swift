import Foundation

class RecommendationService {
    static let shared = RecommendationService()
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    func getRecommendations(projectId: String) async throws -> [PerfumeRecommendation] {
        // ProjectId로부터 추천을 받아오는 로직이 필요하다면 구현 필요
        // 현재는 일반적인 향수 추천을 반환
        let perfumeResponses = try await networkManager.fetchPerfumes()
        return perfumeResponses.map { perfume in
            PerfumeRecommendation(
                id: perfume.id,
                name: perfume.name,
                brand: perfume.brand,
                notes: "Top: \(perfume.notes.top.joined(separator: ", "))",
                imageUrl: perfume.imageURL,
                score: perfume.rating,
                emotionTags: perfume.emotionTags,
                similarity: String(format: "%.2f", perfume.similarity)
            )
        }
    }
    
    func saveRecommendations(userId: String, recommendRound: Int, recommendations: [PerfumeRecommendationItem]) async throws {
        try await networkManager.saveRecommendations(
            userId: userId,
            recommendRound: recommendRound,
            recommendations: recommendations
        )
    }
    
    func saveRecommendationHistory(
        userId: String,
        recommendationId: String,
        selectedPerfumeId: String
    ) async throws {
        let url = URL(string: "\(networkManager.baseURL)/recommendations/history")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let request = [
            "user_id": userId,
            "recommendation_id": recommendationId,
            "selected_perfume_id": selectedPerfumeId
        ]
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request)
        
        let (_, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
} 