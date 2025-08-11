import Foundation

struct RecommendationRequest: Codable {
    let userId: String
    let preferences: PerfumePreferences
    let userPreferences: UserPreferences
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case preferences
        case userPreferences = "user_preferences"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        preferences = try container.decode(PerfumePreferences.self, forKey: .preferences)
        userPreferences = try container.decode(UserPreferences.self, forKey: .userPreferences)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(preferences, forKey: .preferences)
        try container.encode(userPreferences, forKey: .userPreferences)
    }
}

struct RecommendationResponse: Codable {
    let recommendations: [PerfumeRecommendation]
    let userPreferences: UserPreferences
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case recommendations
        case userPreferences = "user_preferences"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recommendations = try container.decode([PerfumeRecommendation].self, forKey: .recommendations)
        userPreferences = try container.decode(UserPreferences.self, forKey: .userPreferences)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(recommendations, forKey: .recommendations)
        try container.encode(userPreferences, forKey: .userPreferences)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

struct RecommendationResult: Codable {
    let perfume: Perfume
    let matchScore: Int
    let reason: String
} 