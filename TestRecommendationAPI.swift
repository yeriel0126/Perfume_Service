import Foundation

class TestRecommendationAPI {
    
    static func testSecondRecommendation() async {
        print("🧪 [API 테스트 시작] 2차 추천 API 테스트")
        
        // 사용자가 제공한 테스트 데이터
        let userNoteScores = [
            "amber": 3,
            "citrus": 2,
            "jasmine": 5,
            "musk": 0,
            "rose": 4,
            "vanilla": 1
        ]
        
        let emotionProba = [0.01, 0.03, 0.85, 0.02, 0.05, 0.04]
        let selectedIdx = [23, 45, 102, 200, 233, 305, 399, 410, 487, 512]
        
        // 사용자 선호도를 UserPreferencesForSecond 형식으로 직접 설정
        let userPreferences = UserPreferencesForSecond(
            gender: "women",
            seasonTags: "spring", 
            timeTags: "day",
            desiredImpression: "confident, fresh",
            activity: "casual",
            weather: "hot"
        )
        
        // 요청 데이터 구성
        let requestBody = SecondRecommendationRequest(
            user_preferences: userPreferences,
            user_note_scores: userNoteScores,
            emotion_proba: emotionProba,
            selected_idx: selectedIdx
        )
        
        do {
            print("📤 [테스트 요청] 데이터 전송")
            print("   - 노트 점수: \(userNoteScores)")
            print("   - 감정 확률: \(emotionProba)")
            print("   - 선택 인덱스: \(selectedIdx)")
            print("   - 사용자 선호도:")
            print("     * gender: \(userPreferences.gender ?? "nil")")
            print("     * season_tags: \(userPreferences.season_tags ?? "nil")")
            print("     * time_tags: \(userPreferences.time_tags ?? "nil")")
            print("     * desired_impression: \(userPreferences.desired_impression ?? "nil")")
            print("     * activity: \(userPreferences.activity ?? "nil")")
            print("     * weather: \(userPreferences.weather ?? "nil")")
            
            // APIClient를 통한 호출
            let response = try await APIClient.shared.getSecondRecommendation(requestData: requestBody)
            
            print("✅ [테스트 성공] \(response.recommendations.count)개 추천 결과 받음")
            
            // 결과 상세 출력
            for (index, recommendation) in response.recommendations.enumerated() {
                print("   \(index + 1). 향수: \(recommendation.name)")
                print("      브랜드: \(recommendation.brand)")
                print("      점수: \(String(format: "%.3f", recommendation.final_score))")
                print("      감정 클러스터: \(recommendation.emotion_cluster)")
                print("      이미지 URL: \(recommendation.image_url)")
                print("      ---")
            }
            
        } catch {
            print("❌ [테스트 실패] \(error)")
            
            // 더 상세한 오류 정보
            if let urlError = error as? URLError {
                print("   URLError 코드: \(urlError.code)")
                print("   URLError 설명: \(urlError.localizedDescription)")
            }
        }
    }
}

// UserPreferencesForSecond 구조체 정의 (APIClient.swift에서 가져옴)
struct UserPreferencesForSecond: Codable {
    let gender: String?
    let season_tags: String?
    let time_tags: String?
    let desired_impression: String?
    let activity: String?
    let weather: String?
    
    init(gender: String? = nil, seasonTags: String? = nil, timeTags: String? = nil, desiredImpression: String? = nil, activity: String? = nil, weather: String? = nil) {
        self.gender = gender
        self.season_tags = seasonTags
        self.time_tags = timeTags
        self.desired_impression = desiredImpression
        self.activity = activity
        self.weather = weather
    }
}

// SecondRecommendationRequest 구조체 정의
struct SecondRecommendationRequest: Codable {
    let user_preferences: UserPreferencesForSecond
    let user_note_scores: [String: Int]
    let emotion_proba: [Double]
    let selected_idx: [Int]
}

// SecondRecommendationResponse 구조체 정의
struct SecondRecommendationResponse: Codable {
    let recommendations: [SecondRecommendationItem]
}

// SecondRecommendationItem 구조체 정의
struct SecondRecommendationItem: Codable {
    let name: String
    let brand: String
    let final_score: Double
    let emotion_cluster: Int
    let image_url: String
}

// 테스트 실행 함수
@MainActor
func runAPITest() {
    Task {
        await TestRecommendationAPI.testSecondRecommendation()
    }
} 