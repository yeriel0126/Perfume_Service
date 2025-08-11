import Foundation

struct ProjectModel: Codable, Identifiable {
    let id: String
    let name: String
    let userId: String
    let preferences: [PreferenceRating]
    let recommendations: [PerfumeRecommendation]
    let createdAt: Date
    let updatedAt: Date
    let tags: [String]
    var isFavorite: Bool
    
    init(id: String, name: String, userId: String, preferences: [PreferenceRating], recommendations: [PerfumeRecommendation], createdAt: Date, updatedAt: Date, tags: [String], isFavorite: Bool) {
        self.id = id
        self.name = name
        self.userId = userId
        self.preferences = preferences
        self.recommendations = recommendations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.isFavorite = isFavorite
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
        case isFavorite = "is_favorite"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        userId = try container.decode(String.self, forKey: .userId)
        preferences = try container.decode([PreferenceRating].self, forKey: .preferences)
        recommendations = try container.decode([PerfumeRecommendation].self, forKey: .recommendations)
        tags = try container.decode([String].self, forKey: .tags)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        
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
        try container.encode(isFavorite, forKey: .isFavorite)
        
        let dateFormatter = ISO8601DateFormatter()
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
} 