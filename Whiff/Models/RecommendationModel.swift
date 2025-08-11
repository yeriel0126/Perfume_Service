import Foundation

// MARK: - 추천 모델 타입

enum RecommendationModelType: String, CaseIterable {
    case aiRecommendation = "AI 추천"
    
    var description: String {
        switch self {
        case .aiRecommendation:
            return "감정 클러스터 기반 고도화 모델"
        }
    }
    
    var icon: String {
        switch self {
        case .aiRecommendation:
            return "brain"
        }
    }
    
    var buttonText: String {
        switch self {
        case .aiRecommendation:
            return "AI 추천으로 시작하기"
        }
    }
}
