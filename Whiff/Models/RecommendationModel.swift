import Foundation

// MARK: - 추천 모델 타입

enum RecommendationModelType: String, CaseIterable {
    case standard = "일반 추천"
    case cluster = "클러스터 추천 (신규)"
    
    var description: String {
        switch self {
        case .standard:
            return "검증된 기본 추천 모델"
        case .cluster:
            return "AI 클러스터 기반 고도화 모델"
        }
    }
    
    var icon: String {
        switch self {
        case .standard:
            return "brain"
        case .cluster:
            return "brain.head.profile"
        }
    }
    
    var buttonText: String {
        switch self {
        case .standard:
            return "일반 추천으로 시작하기"
        case .cluster:
            return "클러스터 추천으로 시작하기"
        }
    }
} 