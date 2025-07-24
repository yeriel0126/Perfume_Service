import Foundation

struct EmotionTag: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let confidence: Double
    let category: String?
    let description: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: EmotionTag, rhs: EmotionTag) -> Bool {
        lhs.id == rhs.id
    }
}

struct EmotionTagResponse: Codable {
    let tags: [EmotionTag]
    let summary: String?
    let dominantEmotion: String?
}

struct EmotionAnalysisError: Codable {
    let error: String
    let message: String
    let statusCode: Int
} 