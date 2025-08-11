import Foundation

struct PerfumePreferences: Codable {
    let gender: String
    let seasonTags: String
    let timeTags: String
    let desiredImpression: String
    let activity: String
    let weather: String
    
    // 디버깅용 설명 속성
    var description: String {
        return "gender=\(gender), season=\(seasonTags), time=\(timeTags), impression=\(desiredImpression), activity=\(activity), weather=\(weather)"
    }
    
    // 기본값 생성자 추가 (1차 입력값)
    init(gender: String = "women",
         seasonTags: String = "spring", 
         timeTags: String = "day",
         desiredImpression: String = "elegant",
         activity: String = "date",
         weather: String = "sunny") {
        self.gender = gender
        self.seasonTags = seasonTags
        self.timeTags = timeTags
        self.desiredImpression = desiredImpression
        self.activity = activity
        self.weather = weather
    }
    
    // 백엔드 API 전용 구조체 (1차 추천용 - 단순 설문 응답만)
    struct APIRequest: Codable {
        let gender: String
        let season_tags: String
        let time_tags: String
        let desired_impression: String
        let activity: String
        let weather: String
    }
    
    // 백엔드 API 형식으로 변환하는 메서드 (1차 추천용)
    func toAPIFormat() -> APIRequest {
        return APIRequest(
            gender: mapGender(gender),
            season_tags: mapSeason(seasonTags),
            time_tags: mapTime(timeTags),
            desired_impression: mapDesiredImpression(desiredImpression),
            activity: mapActivity(activity),
            weather: mapWeather(weather)
        )
    }

    // Gender 매핑 (Male->men, Female->women, Unisex->unisex)
    private func mapGender(_ gender: String) -> String {
        switch gender.lowercased() {
        case "male": return "men"
        case "female": return "women"  
        case "unisex": return "unisex"
        default: return "unisex" // 기본값
        }
    }
    
    // Desired Impression 매핑 (백엔드 허용 조합으로 변환)
    private func mapDesiredImpression(_ impression: String) -> String {
        // 빈 문자열 처리
        if impression.isEmpty {
            return "elegant, friendly" // 기본값
        }
        
        // 사용자가 선택한 2개 인상을 개별적으로 분리
        let selectedImpressions = impression.lowercased()
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .sorted()
        
        // 백엔드 허용 조합 목록
        let allowedCombinations = [
            "confident, fresh",
            "confident, mysterious", 
            "elegant, friendly",
            "pure, friendly"
        ]
        
        // 선택된 조합이 이미 허용되는 조합인지 확인
        let userCombination = selectedImpressions.joined(separator: ", ")
        if allowedCombinations.contains(userCombination) {
            return userCombination
        }
        
        print("🔄 [인상 매핑] 사용자 선택: '\(userCombination)' -> 허용 조합으로 변환")
        
        // 각 인상별 우선순위 매핑
        var mappedCombination = "elegant, friendly" // 기본값
        
        // 우선순위 기반 매핑 로직
        if selectedImpressions.contains("confident") {
            if selectedImpressions.contains("mysterious") {
                mappedCombination = "confident, mysterious"
            } else {
                mappedCombination = "confident, fresh" // confident + 다른 것
            }
        } else if selectedImpressions.contains("pure") {
            mappedCombination = "pure, friendly" // pure가 포함되면 pure, friendly
        } else if selectedImpressions.contains("elegant") {
            mappedCombination = "elegant, friendly" // elegant가 포함되면 elegant, friendly
        } else if selectedImpressions.contains("mysterious") {
            mappedCombination = "confident, mysterious" // mysterious가 포함되면 confident, mysterious
        } else if selectedImpressions.contains("fresh") {
            mappedCombination = "confident, fresh" // fresh가 포함되면 confident, fresh
        } else if selectedImpressions.contains("friendly") {
            mappedCombination = "elegant, friendly" // friendly가 포함되면 elegant, friendly
        }
        
        print("🎯 [인상 매핑] 최종 결과: '\(mappedCombination)'")
        return mappedCombination
    }
    
    // Weather 매핑 (백엔드 허용 값에 맞춤)
    private func mapWeather(_ weather: String) -> String {
        switch weather.lowercased() {
        case "hot": return "hot"
        case "cold": return "cold"
        case "rainy": return "rainy"
        case "any": return "any"
        // 기존 매핑도 유지
        case "sunny", "clear": return "hot"
        case "winter": return "cold"
        case "rain": return "rainy"
        default: return "any" // 기본값
        }
    }
    
    // Season 매핑
    private func mapSeason(_ season: String) -> String {
        return season.lowercased()
    }
    
    // Time 매핑
    private func mapTime(_ time: String) -> String {
        return time.lowercased()
    }
    
    // Activity 매핑
    private func mapActivity(_ activity: String) -> String {
        return activity.lowercased()
    }
    
    enum CodingKeys: String, CodingKey {
        case gender
        case seasonTags = "season_tags"
        case timeTags = "time_tags"
        case desiredImpression = "desired_impression"
        case activity
        case weather
    }
}

// MARK: - 노트 평가 모델

struct NoteEvaluationItem: Identifiable, Codable {
    var id = UUID()
    let noteName: String
    var rating: Int
    
    init(noteName: String, rating: Int = 3) {
        self.noteName = noteName
        self.rating = rating
    }
}

struct NoteEvaluationData: Codable {
    let extractedNotes: [String]
    var userRatings: [String: Int]
    
    init(extractedNotes: [String]) {
        self.extractedNotes = extractedNotes
        // 모든 노트를 중립(3점)으로 초기화
        self.userRatings = Dictionary(uniqueKeysWithValues: extractedNotes.map { ($0, 3) })
    }
    
    // 사용자 평가 업데이트
    mutating func updateRating(for note: String, rating: Int) {
        userRatings[note] = rating
    }
    
    // 평가 완료 여부 확인
    var isComplete: Bool {
        return userRatings.values.allSatisfy { $0 != 3 } // 모든 노트가 중립이 아님
    }
    
    // 평가된 노트 개수
    var evaluatedCount: Int {
        return userRatings.values.filter { $0 != 3 }.count
    }
}

struct UserPreferences: Codable {
    let preferredNotes: [String]
    let preferredBrands: [String]
    let priceRange: ClosedRange<Double>
    let preferredGender: String
    
    enum CodingKeys: String, CodingKey {
        case preferredNotes = "preferred_notes"
        case preferredBrands = "preferred_brands"
        case priceRange = "price_range"
        case preferredGender = "preferred_gender"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        preferredNotes = try container.decode([String].self, forKey: .preferredNotes)
        preferredBrands = try container.decode([String].self, forKey: .preferredBrands)
        let priceRangeArray = try container.decode([Double].self, forKey: .priceRange)
        guard priceRangeArray.count == 2 else {
            throw DecodingError.dataCorruptedError(forKey: .priceRange, in: container, debugDescription: "Price range must contain exactly two values")
        }
        priceRange = priceRangeArray[0]...priceRangeArray[1]
        preferredGender = try container.decode(String.self, forKey: .preferredGender)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(preferredNotes, forKey: .preferredNotes)
        try container.encode(preferredBrands, forKey: .preferredBrands)
        try container.encode([priceRange.lowerBound, priceRange.upperBound], forKey: .priceRange)
        try container.encode(preferredGender, forKey: .preferredGender)
    }
} 