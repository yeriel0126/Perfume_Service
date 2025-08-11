import Foundation

// MARK: - Perfume Models

struct Perfume: Codable, Identifiable {
    let id: String
    let name: String
    let brand: String
    let imageURL: String
    let price: Double
    let description: String
    let notes: PerfumeNotes
    let rating: Double
    let emotionTags: [String]
    let similarity: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case imageURL = "image_url"
        case price
        case description
        case notes
        case rating
        case emotionTags = "emotion_tags"
        case similarity
    }
}

struct PerfumeDetail: Codable {
    let id: String?
    let name: String
    let brand: String
    let description: String
    let notes: String?
    let imageUrl: String?
    let rating: Double?
    let reviewCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case description
        case notes
        case imageUrl = "image_url"
        case rating
        case reviewCount = "review_count"
    }
}

struct PerfumeReview: Codable {
    let id: String
    let userId: String
    let userName: String
    let rating: Int
    let comment: String
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case rating
        case comment
        case date
    }
}

// MARK: - Perfume Recommendation Models

extension Perfume {
    func asRecommendation(emotionTags: [String], similarity: Double) -> PerfumeRecommendation {
        let notesString = "Top: \(notes.top.joined(separator: ", "))\nMiddle: \(notes.middle.joined(separator: ", "))\nBase: \(notes.base.joined(separator: ", "))"
        
        return PerfumeRecommendation(
            id: id,
            name: name,
            brand: brand,
            notes: notesString,
            imageUrl: imageURL,
            score: similarity,
            emotionTags: emotionTags,
            similarity: String(format: "%.2f", similarity)
        )
    }
}

struct PerfumeRecommendation: Codable, Identifiable {
    let id: String?
    let name: String
    let brand: String
    let notes: String?
    let imageUrl: String?
    let score: Double?
    let emotionTags: [String]?
    let similarity: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case notes
        case imageUrl = "image_url"
        case score
        case emotionTags = "emotion_tags"
        case similarity
    }
}

struct PerfumeScore: Codable, Identifiable {
    let id: String
    let score: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case score
    }
}
