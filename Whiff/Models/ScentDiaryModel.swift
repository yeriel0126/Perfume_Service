import Foundation

// MARK: - 시향 일기 작성 요청 모델 (백엔드 API용)
struct ScentDiaryRequest: Codable {
    let userId: String
    let perfumeName: String
    let content: String
    let isPublic: Bool
    let emotionTags: String // JSON 배열 문자열로 변경
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case perfumeName = "perfume_name"
        case content
        case isPublic = "is_public"
        case emotionTags = "emotion_tags"
        case imageUrl = "image_url"
    }
    
    // 편의 초기화 메서드 (배열을 JSON 문자열로 변환)
    init(userId: String, perfumeName: String, content: String, isPublic: Bool, emotionTagsArray: [String], imageUrl: String? = nil) {
        self.userId = userId
        self.perfumeName = perfumeName
        self.content = content
        self.isPublic = isPublic
        self.imageUrl = imageUrl
        
        // 배열을 JSON 문자열로 변환 (JSONSerialization 사용)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: emotionTagsArray, options: [])
            self.emotionTags = String(data: jsonData, encoding: .utf8) ?? "[]"
            print("✅ [ScentDiaryRequest] 감정 태그 JSON 변환 성공: \(self.emotionTags)")
        } catch {
            print("❌ [ScentDiaryRequest] 감정 태그 JSON 변환 실패: \(error)")
            self.emotionTags = "[]"
        }
    }
}

// MARK: - 시향 일기 목록 응답 모델
struct ScentDiaryListResponse: Codable {
    let diaries: [ScentDiaryModel]
}

// MARK: - 백엔드 API 응답 래퍼 (result 구조)
struct ScentDiaryBackendResponse: Codable {
    let message: String
    let result: ScentDiaryResultData
}

struct ScentDiaryResultData: Codable {
    let diaries: [ScentDiaryModel]
    let totalCount: Int?
    let page: Int?
    let size: Int?
    let hasNext: Bool?
    
    enum CodingKeys: String, CodingKey {
        case diaries
        case totalCount = "total_count"
        case page
        case size
        case hasNext = "has_next"
    }
}

struct ScentDiaryModel: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let userProfileImage: String
    let perfumeId: String?
    let perfumeName: String
    let brand: String?
    let content: String
    let tags: [String] // emotionTags와 호환
    var likes: Int = 0
    var comments: Int
    let isPublic: Bool // 백엔드 API 추가 필드
    var imageUrl: String? // 시향 일기 이미지 URL
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case userProfileImage = "user_profile_image"
        case perfumeId = "perfume_id"
        case perfumeName = "perfume_name"
        case brand
        case content
        case tags // 백엔드는 tags로 사용
        case likes
        case comments
        case isPublic = "is_public"
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom decoder to handle missing id field
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ID 처리 - null 값 처리
        if let idValue = try? container.decodeIfPresent(String.self, forKey: .id), !idValue.isEmpty {
            self.id = idValue
        } else {
            // ID가 null이거나 빈 문자열인 경우 UUID 생성
            self.id = UUID().uuidString
            print("⚠️ [ScentDiaryModel] ID가 null 또는 빈값, UUID 생성: \(self.id)")
        }
        
        // 사용자 정보 처리
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? "unknown"
        
        // 사용자명 매핑 로직
        if let backendUserName = try? container.decodeIfPresent(String.self, forKey: .userName) {
            let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
            let currentUserName = UserDefaults.standard.string(forKey: "currentUserName") ?? ""
            
            if backendUserName == currentUserId && !currentUserName.isEmpty {
                self.userName = currentUserName
            } else if backendUserName.isEmpty || backendUserName == "null" {
                self.userName = "익명 사용자"
            } else {
                self.userName = backendUserName
            }
        } else {
            self.userName = "익명 사용자"
        }
        
        self.userProfileImage = try container.decodeIfPresent(String.self, forKey: .userProfileImage) ?? "default_profile"
        self.perfumeId = try container.decodeIfPresent(String.self, forKey: .perfumeId)
        self.perfumeName = try container.decodeIfPresent(String.self, forKey: .perfumeName) ?? "향수 없음"
        self.brand = try container.decodeIfPresent(String.self, forKey: .brand)
        self.content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        
        // emotion_tags 파싱 - 여러 형태 지원
        if let tagArray = try? container.decodeIfPresent([String].self, forKey: .tags) {
            self.tags = tagArray.filter { !$0.isEmpty }
            print("✅ [태그 파싱] 배열 형태: \(self.tags)")
        } else if let tagString = try? container.decodeIfPresent(String.self, forKey: .tags) {
            if tagString.isEmpty || tagString == "null" {
                self.tags = []
            } else {
                // JSON 문자열 파싱 시도
                if let data = tagString.data(using: .utf8),
                   let parsedTags = try? JSONSerialization.jsonObject(with: data) as? [String] {
                    self.tags = parsedTags.filter { !$0.isEmpty }
                    print("✅ [태그 파싱] JSON 문자열 파싱: \(self.tags)")
                } else {
                    // 쉼표로 구분된 문자열 처리
                    self.tags = tagString.components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    print("✅ [태그 파싱] 쉼표 구분 문자열: \(self.tags)")
                }
            }
        } else {
            self.tags = []
            print("⚠️ [태그 파싱] 태그 정보 없음")
        }
        
        // 좋아요, 댓글 수 처리
        self.likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        self.comments = try container.decodeIfPresent(Int.self, forKey: .comments) ?? 0
        
        // 공개/비공개 설정
        self.isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? true
        
        // 이미지 URL 처리
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        if let imageUrl = self.imageUrl, imageUrl.isEmpty || imageUrl == "null" {
            self.imageUrl = nil
        }
        
        // 날짜 처리
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        if let createdAtString = try? container.decodeIfPresent(String.self, forKey: .createdAt),
           let date = dateFormatter.date(from: createdAtString) {
            self.createdAt = date
        } else {
            // 다른 날짜 형식도 시도
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let createdAtString = try? container.decodeIfPresent(String.self, forKey: .createdAt),
               let date = dateFormatter.date(from: createdAtString) {
                self.createdAt = date
            } else {
                self.createdAt = Date()
                print("⚠️ [날짜 파싱] created_at 파싱 실패, 현재 시간 사용")
            }
        }
        
        if let updatedAtString = try? container.decodeIfPresent(String.self, forKey: .updatedAt),
           let date = dateFormatter.date(from: updatedAtString) {
            self.updatedAt = date
        } else {
            self.updatedAt = self.createdAt
        }
    }
    
    // 날짜 파싱 헬퍼 메서드
    private static func parseDate(from string: String) -> Date? {
        // 1. ISO8601DateFormatter 시도
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: string) {
            return date
        }
        
        // 2. RFC3339 형식 시도
        if let date = DateFormatter.rfc3339.date(from: string) {
            return date
        }
        
        // 3. 표준 형식 시도
        if let date = DateFormatter.standard.date(from: string) {
            return date
        }
        
        // 4. 기본 ISO8601 변형들 시도
        let additionalFormatters = [
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in additionalFormatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        print("⚠️ [ScentDiary] 날짜 파싱 실패: \(string)")
        return nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // 필수 필드 인코딩
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(userName, forKey: .userName)
        try container.encode(perfumeName, forKey: .perfumeName)
        try container.encode(content, forKey: .content)
        
        // 선택적 필드 인코딩
        try container.encode(userProfileImage, forKey: .userProfileImage)
        try container.encodeIfPresent(perfumeId, forKey: .perfumeId)
        try container.encodeIfPresent(brand, forKey: .brand)
        try container.encode(tags, forKey: .tags)
        try container.encode(likes, forKey: .likes)
        try container.encode(comments, forKey: .comments)
        try container.encode(isPublic, forKey: .isPublic)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        
        // 날짜 인코딩
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
    }
    
    init(id: String,
         userId: String,
         userName: String,
         userProfileImage: String = "default_profile",
         perfumeId: String? = nil,
         perfumeName: String,
         brand: String? = nil,
         content: String,
         tags: [String] = [],
         likes: Int = 0,
         comments: Int = 0,
         isPublic: Bool = true,
         imageUrl: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userProfileImage = userProfileImage
        self.perfumeId = perfumeId
        self.perfumeName = perfumeName
        self.brand = brand
        self.content = content
        self.tags = tags
        self.likes = likes
        self.comments = comments
        self.isPublic = isPublic
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - 백엔드 API 호환성 메서드
    
    /// ScentDiaryRequest로 변환 (일기 작성용)
    func toRequest() -> ScentDiaryRequest {
        return ScentDiaryRequest(
            userId: userId,
            perfumeName: perfumeName,
            content: content,
            isPublic: isPublic,
            emotionTagsArray: tags,
            imageUrl: imageUrl
        )
    }
    
    /// 감정 태그들 (tags 별칭)
    var emotionTags: [String] {
        return tags
    }
}

// MARK: - DateFormatter Extensions
extension DateFormatter {
    static let rfc3339: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    static let standard: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
} 
