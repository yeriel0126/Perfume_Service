import Foundation

struct PreferenceRating: Codable {
    let perfumeId: String
    let rating: Int
    let notes: String
    
    enum CodingKeys: String, CodingKey {
        case perfumeId = "perfume_id"
        case rating
        case notes
    }
    
    init(perfumeId: String, rating: Int, notes: String = "") {
        self.perfumeId = perfumeId
        self.rating = rating
        self.notes = notes
    }
}

struct Project: Codable, Identifiable {
    let id: String
    let name: String
    let userId: String
    let preferences: [PreferenceRating]
    let recommendations: [Perfume]
    let createdAt: Date
    let updatedAt: Date
    let tags: [String]
    
    init(id: UUID, name: String, recommendations: [Perfume], emotionSummary: String, createdDate: Date, userPreferences: PerfumePreferences?, userNoteRatings: [String: Int]) {
        self.id = id.uuidString
        self.name = name
        self.userId = "current_user" // TODO: 실제 사용자 ID로 변경
        self.preferences = [] // 노트 평가를 PreferenceRating으로 변환할 수도 있음
        self.recommendations = recommendations
        self.createdAt = createdDate
        self.updatedAt = createdDate
        
        // 태그 생성 (감정 분석 요약과 사용자 선호도 기반)
        var generatedTags: [String] = []
        
        if let prefs = userPreferences {
            generatedTags.append(prefs.gender)
            generatedTags.append(prefs.seasonTags)
            generatedTags.append(prefs.timeTags)
        }
        
        // 높게 평가한 노트들을 태그로 추가
        let likedNotes = userNoteRatings.filter { $0.value >= 4 }.keys
        generatedTags.append(contentsOf: likedNotes.prefix(3))
        
        self.tags = generatedTags
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case userId = "user_id"
        case preferences
        case recommendations
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        userId = try container.decode(String.self, forKey: .userId)
        preferences = try container.decode([PreferenceRating].self, forKey: .preferences)
        recommendations = try container.decode([Perfume].self, forKey: .recommendations)
        tags = try container.decode([String].self, forKey: .tags)
        
        let dateFormatter = ISO8601DateFormatter()
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        
        guard let createdAtDate = dateFormatter.date(from: createdAtString),
              let updatedAtDate = dateFormatter.date(from: updatedAtString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match format")
        }
        
        createdAt = createdAtDate
        updatedAt = updatedAtDate
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(userId, forKey: .userId)
        try container.encode(preferences, forKey: .preferences)
        try container.encode(recommendations, forKey: .recommendations)
        try container.encode(tags, forKey: .tags)
        
        let dateFormatter = ISO8601DateFormatter()
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
} 