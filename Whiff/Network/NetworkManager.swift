import Foundation
import UIKit

// MARK: - API Response Models

struct APIResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: T
}

struct PerfumesData: Codable {
    let perfumes: [PerfumeResponseData]
}

struct PerfumeResponseData: Codable {
    let name: String
    let brand: String
    let imageUrl: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case brand
        case imageUrl = "image_url"
    }
    
    // PerfumeResponseData를 Perfume 모델로 변환
    func toPerfume() -> Perfume {
        // 백엔드 이미지 URL이 있으면 사용, 없거나 빈 값이면 플레이스홀더 생성
        let finalImageURL = imageUrl.trimmingCharacters(in: .whitespaces).isEmpty ? 
            generateSafeImageURL(for: name, brand: brand) : imageUrl
        
        return Perfume(
            id: "\(brand.lowercased().replacingOccurrences(of: " ", with: "_"))_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))",
            name: name,
            brand: brand,
            imageURL: finalImageURL,
            price: 0.0, // 기본값
            description: "\(brand)의 \(name) 향수입니다.", // 기본 설명
            notes: PerfumeNotes(top: [], middle: [], base: []), // 빈 노트
            rating: 4.0, // 기본 평점
            emotionTags: [], // 빈 감정 태그
            similarity: 0.0 // 기본 유사도
        )
    }
    
    // 안정적인 이미지 URL 생성 헬퍼 함수
    private func generateSafeImageURL(for name: String, brand: String) -> String {
        // 향수 이름과 브랜드를 조합하여 일관된 시드 생성
        let combined = "\(brand)\(name)".lowercased().replacingOccurrences(of: " ", with: "")
        let seed = abs(combined.hashValue) % 1000 + 1
        return "https://picsum.photos/200/300?random=\(seed)"
    }
}

// MARK: - Models

// Perfume 타입은 Models/Perfume.swift에서 가져옴

struct Review: Codable {
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

// MARK: - Cluster Recommendation Models

struct ClusterRecommendResponse: Codable {
    let cluster: Int
    let description: String
    let proba: [Double]
    let recommended_notes: [String]
    let selected_idx: [Int]
    let metadata: ClusterMetadata?
    
    struct ClusterMetadata: Codable {
        let model_version: String?
        let processing_time: Double?
        let confidence: Double?
    }
}

// MARK: - Network Models

struct PerfumeRecommendationItem: Codable {
    let perfumeName: String
    let perfumeBrand: String
    let score: Int?
    
    enum CodingKeys: String, CodingKey {
        case perfumeName = "perfume_name"
        case perfumeBrand = "perfume_brand"
        case score
    }
}

struct SaveRecommendationsRequest: Codable {
    let userId: String
    let recommendRound: Int
    let recommendations: [PerfumeRecommendationItem]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case recommendRound = "recommend_round"
        case recommendations
    }
}

struct PerfumeFilters: Codable {
    let brand: String?
    let priceRange: ClosedRange<Double>?
    let gender: String?
    let sortBy: String?
    
    func toQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        if let brand = brand {
            items.append(URLQueryItem(name: "brand", value: brand))
        }
        if let priceRange = priceRange {
            items.append(URLQueryItem(name: "min_price", value: String(priceRange.lowerBound)))
            items.append(URLQueryItem(name: "max_price", value: String(priceRange.upperBound)))
        }
        if let gender = gender {
            items.append(URLQueryItem(name: "gender", value: gender))
        }
        if let sortBy = sortBy {
            items.append(URLQueryItem(name: "sort_by", value: sortBy))
        }
        return items
    }
}

struct PerfumeDetailResponseData: Codable {
    let name: String
    let brand: String
    let imageUrl: String
    let notes: String?
    let emotionTags: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case brand
        case imageUrl = "image_url"
        case notes
        case emotionTags = "emotion_tags"
    }
    
    // PerfumeDetailResponseData를 Perfume 모델로 변환
    func toPerfume() -> Perfume {
        return Perfume(
            id: "\(brand.lowercased().replacingOccurrences(of: " ", with: "_"))_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))",
            name: name,
            brand: brand,
            imageURL: imageUrl.isEmpty ? generateSafeImageURL(for: name, brand: brand) : imageUrl,
            price: 0.0,
            description: notes ?? "\(brand)의 \(name) 향수입니다.",
            notes: PerfumeNotes(top: [], middle: [], base: []),
            rating: 4.5,
            emotionTags: emotionTags?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) } ?? [],
            similarity: 0.0
        )
    }
    
    // 안정적인 이미지 URL 생성 헬퍼 함수
    private func generateSafeImageURL(for name: String, brand: String) -> String {
        // 향수 이름과 브랜드를 조합하여 일관된 시드 생성
        let combined = "\(brand)\(name)".lowercased().replacingOccurrences(of: " ", with: "")
        let seed = abs(combined.hashValue) % 1000 + 1
        return "https://picsum.photos/200/300?random=\(seed)"
    }
}

// MARK: - NetworkManager

class NetworkManager {
    static let shared = NetworkManager()
    let baseURL = "https://whiff-api-9nd8.onrender.com"
    
    private init() {}
    
    // MARK: - 1차 추천 API (감정 클러스터 기반)
    
    func getFirstRecommendations(preferences: PerfumePreferences, onRetry: ((Int) async -> Void)? = nil) async throws -> FirstRecommendationResponse {
        // 백엔드 권장: 새로운 클러스터 기반 API 사용
        let url = URL(string: "\(baseURL)/perfumes/recommend-cluster")!
        
        // 재시도 로직 (최대 3회)
        for attempt in 1...3 {
            do {
                print("🚀 [1차 추천 API 요청] 시도 \(attempt)/3")
                
                // 재시도 상태 업데이트
                await onRetry?(attempt)
                
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.timeoutInterval = 60.0  // 30초 → 60초로 증가
                
                // 1차 추천은 단순한 설문 응답만 전송 (원래대로)
                let apiPreferences = preferences.toAPIFormat()
                
                // JSONEncoder를 사용해서 구조체를 JSON으로 인코딩
                let encoder = JSONEncoder()
                urlRequest.httpBody = try encoder.encode(apiPreferences)
                
                // 캐싱 방지를 위한 헤더 추가
                let requestId = UUID().uuidString
                let timestamp = Date().timeIntervalSince1970
                urlRequest.setValue(requestId, forHTTPHeaderField: "X-Request-ID")
                urlRequest.setValue(String(timestamp), forHTTPHeaderField: "X-Timestamp")
                urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                
                // 디버깅을 위한 요청 정보 출력
                print("   URL: \(url.absoluteString)")
                print("   Timeout: 60초")
                print("   Request-ID: \(requestId)")
                if let bodyData = urlRequest.httpBody,
                   let bodyString = String(data: bodyData, encoding: .utf8) {
                    print("   Body: \(bodyString)")
                }
                
                let (data, httpResponse) = try await URLSession.shared.data(for: urlRequest)
                
                guard let httpResponse = httpResponse as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                print("🔍 [1차 추천 API 응답] 상태 코드: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 [1차 추천 API 응답] Body: \(responseString.prefix(500))...")
                }
                
                guard httpResponse.statusCode == 200 else {
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("❌ [1차 추천 API 오류] \(httpResponse.statusCode): \(errorString)")
                    }
                    throw URLError(.badServerResponse)
                }
                
                // 성공적으로 응답을 받은 경우 디코딩 진행
                let decoder = JSONDecoder()
                
                do {
                    // 새로운 클러스터 응답 형식으로 디코딩
                    let clusterResponse = try decoder.decode(ClusterRecommendResponse.self, from: data)
                    
                    print("✅ [1차 추천 API 성공] 클러스터: \(clusterResponse.cluster), 향수: \(clusterResponse.selected_idx.count)개")
                    print("   🎯 감정 클러스터: \(clusterResponse.description)")
                    print("   📊 확률 분포: \(clusterResponse.proba.map { String(format: "%.2f", $0) }.joined(separator: ", "))")
                    print("   🌿 추천 노트: \(clusterResponse.recommended_notes.prefix(5).joined(separator: ", "))...")
                    
                    // 기존 FirstRecommendationResponse 형식으로 변환
                    let items = clusterResponse.selected_idx.enumerated().map { index, perfumeIndex in
                        FirstRecommendationItem(
                            perfume_index: perfumeIndex,
                            emotion_cluster: clusterResponse.cluster,
                            cluster_proba: clusterResponse.proba[clusterResponse.cluster],
                            rank: index + 1
                        )
                    }
                    
                    let firstResponse = FirstRecommendationResponse(
                        recommendations: items,
                        clusterInfo: ClusterInfo(
                            cluster: clusterResponse.cluster,
                            description: clusterResponse.description,
                            proba: clusterResponse.proba,
                            recommended_notes: clusterResponse.recommended_notes,
                            selected_idx: clusterResponse.selected_idx
                        )
                    )
                    
                    return firstResponse
                    
                } catch {
                    print("⚠️ [클러스터 API 디코딩 실패] 기존 API로 폴백: \(error)")
                    
                    // 폴백: 기존 방식으로 처리
                    let items = try decoder.decode([FirstRecommendationItem].self, from: data)
                    let firstResponse = FirstRecommendationResponse(recommendations: items)
                    
                    print("✅ [1차 추천 API 성공] (폴백) 향수 개수: \(firstResponse.recommendations.count)개")
                    return firstResponse
                }
                
            } catch {
                print("❌ [1차 추천 API] 시도 \(attempt) 실패: \(error)")
                
                // 타임아웃인 경우 특별 처리
                if let urlError = error as? URLError, urlError.code == .timedOut {
                    print("⏰ [타임아웃 감지] Render 서버 Cold Start 가능성")
                    print("💡 [해결책] 15분 비활성 후 첫 요청은 시간이 오래 걸립니다")
                }
                
                // 마지막 시도가 아니면 재시도 전 대기
                if attempt < 3 {
                    print("⏳ [재시도 대기] \(attempt * 2)초 후 재시도...")
                    try? await Task.sleep(nanoseconds: UInt64(attempt * 2) * 1_000_000_000)
                }
            }
        }
        
        // 모든 시도 실패
        print("💥 [1차 추천 API] 모든 시도 실패")
        throw URLError(.unknown)
    }
    
    // MARK: - 2차 추천 API (사용자 노트 점수 기반)
    
    func getSecondRecommendations(
        userPreferences: PerfumePreferences?,
        userNoteScores: [String: Int],
        emotionProba: [Double],
        selectedIdx: [Int]
    ) async throws -> [SecondRecommendationItem] {
        
        let url = URL(string: "\(baseURL)/perfumes/recommend-2nd")!
        
        // 재시도 로직 (최대 3회)
        for attempt in 1...3 {
            do {
                print("🚀 [2차 추천 API 요청] 시도 \(attempt)/3")
                
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.timeoutInterval = 60.0  // 30초 → 60초로 증가
        
                let preferences: UserPreferencesForSecond
                if let userPrefs = userPreferences {
                    // PerfumePreferences를 UserPreferencesForSecond로 변환
                    preferences = UserPreferencesForSecond(
                        gender: userPrefs.gender,
                        season_tags: userPrefs.seasonTags,
                        time_tags: userPrefs.timeTags,
                        desired_impression: userPrefs.desiredImpression,
                        activity: userPrefs.activity,
                        weather: userPrefs.weather
                    )
                } else {
                    preferences = UserPreferencesForSecond()
                }
        
                // 🔥 변환된 사용자 선호도 상세 확인 (첫 번째 시도에서만)
                if attempt == 1 {
        print("🔄 [사용자 선호도 변환 결과]")
        print("   - gender: '\(preferences.gender ?? "nil")'")
        print("   - season_tags: '\(preferences.season_tags ?? "nil")'")
        print("   - time_tags: '\(preferences.time_tags ?? "nil")'")
        print("   - desired_impression: '\(preferences.desired_impression ?? "nil")'")
        print("   - activity: '\(preferences.activity ?? "nil")'")
        print("   - weather: '\(preferences.weather ?? "nil")'")
                }
        
        // 🚨 API 제약사항 확인: selected_idx 최대 20개
        var finalSelectedIdx = selectedIdx
        if selectedIdx.count > 20 {
            finalSelectedIdx = Array(selectedIdx.prefix(20))
                    if attempt == 1 {
            print("⚠️ [API 제약사항] selected_idx를 20개로 제한: \(selectedIdx.count)개 → \(finalSelectedIdx.count)개")
                    }
        }
        
        let requestBody = SecondRecommendationRequest(
            user_preferences: preferences,
            user_note_scores: userNoteScores,
            emotion_proba: emotionProba,
            selected_idx: finalSelectedIdx
        )
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(requestBody)
        
        // 캐싱 방지를 위한 헤더 추가
        let requestId = UUID().uuidString
        let timestamp = Date().timeIntervalSince1970
        urlRequest.setValue(requestId, forHTTPHeaderField: "X-Request-ID")
        urlRequest.setValue(String(timestamp), forHTTPHeaderField: "X-Timestamp")
        urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
                // 디버깅을 위한 요청 정보 출력 (첫 번째 시도에서만)
                if attempt == 1 {
        print("   URL: \(url.absoluteString)")
                    print("   Timeout: 60초")
        print("   Request-ID: \(requestId)")
        print("   Timestamp: \(timestamp)")
        if let bodyData = urlRequest.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
                        print("   Body: \(bodyString.prefix(300))...")
            }
        }
        
        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("🔍 [2차 추천 API 응답] 상태 코드: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 [2차 추천 API 응답] Body: \(responseString.prefix(500))...")
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [2차 추천 API 오류] \(httpResponse.statusCode): \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        // 응답을 디코딩
        let decoder = JSONDecoder()
        // API가 배열을 직접 반환하므로 SecondRecommendationItem 배열로 디코딩
        let secondRecommendations = try decoder.decode([SecondRecommendationItem].self, from: data)
        
                // 🔥 노트 평가 반영도 분석 (성공한 경우에만)
        print("📊 [2차 추천 결과 분석]")
        print("   ✅ 총 추천 개수: \(secondRecommendations.count)")
        
        // 점수 분포 확인
        let scores = secondRecommendations.map { $0.final_score }
        if let minScore = scores.min(), let maxScore = scores.max() {
            let scoreRange = maxScore - minScore
            print("   📈 점수 범위: \(String(format: "%.3f", minScore)) ~ \(String(format: "%.3f", maxScore))")
            print("   📈 점수 차이: \(String(format: "%.3f", scoreRange))")
            
            if scoreRange < 0.1 {
                print("   ⚠️ 점수 차이가 너무 작음 - 노트 평가가 제대로 반영되지 않을 수 있음")
            } else if scoreRange > 0.5 {
                print("   ✅ 충분한 점수 차이 - 노트 평가가 잘 반영됨")
            }
        }
        
        // 브랜드 다양성 확인
        let brands = Set(secondRecommendations.map { $0.brand })
        print("   🏷️ 고유 브랜드 수: \(brands.count)개")
        
        // 감정 클러스터 분포 확인
        let clusters = Set(secondRecommendations.map { $0.emotion_cluster })
        print("   🧠 감정 클러스터 다양성: \(clusters.count)개 클러스터")
        
                print("✅ [2차 추천 API 성공] \(secondRecommendations.count)개 향수 추천 받음")
                return secondRecommendations
                
            } catch {
                print("❌ [2차 추천 API] 시도 \(attempt) 실패: \(error)")
                
                // 네트워크 연결 오류인 경우 특별 처리
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .networkConnectionLost:
                        print("📡 [네트워크 연결 끊김] 재연결 시도 중...")
                    case .timedOut:
                        print("⏰ [타임아웃 감지] 서버 응답 지연")
                    case .notConnectedToInternet:
                        print("🌐 [인터넷 연결 없음] 네트워크 상태 확인 필요")
                    default:
                        print("🔗 [네트워크 오류] 코드: \(urlError.code.rawValue)")
                    }
                }
                
                // 마지막 시도가 아니면 재시도 전 대기
                if attempt < 3 {
                    let waitTime = attempt * 3  // 3초, 6초, 9초
                    print("⏳ [재시도 대기] \(waitTime)초 후 재시도...")
                    try? await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
            }
        }
        }
        
        // 모든 시도 실패
        print("💥 [2차 추천 API] 모든 시도 실패")
        print("🔍 [최종 오류] \(URLError(.unknown))")
        throw URLError(.unknown)
    }
    
    // MARK: - 향수 목록 API
    
    func fetchPerfumes() async throws -> [Perfume] {
        let url = URL(string: "\(baseURL)/perfumes/")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 60.0  // 30초 → 60초로 증가
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(APIResponse<PerfumesData>.self, from: data)
        
        return apiResponse.data.perfumes.map { $0.toPerfume() }
    }
    
    // MARK: - 향수 상세 정보 API
    
    func fetchPerfumeDetail(name: String) async throws -> Perfume {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw URLError(.badURL)
        }
        
        let url = URL(string: "\(baseURL)/perfumes/\(encodedName)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 30.0
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(APIResponse<PerfumeDetailResponseData>.self, from: data)
        
        return apiResponse.data.toPerfume()
    }
    
    // MARK: - 노트 분석 API
    
    func getNoteAnalysis(perfumeIndex: Int) async throws -> NoteAnalysisResponse {
        let url = URL(string: "\(baseURL)/perfumes/note-analysis/\(perfumeIndex)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 30.0
        
        print("🚀 [노트 분석 API 요청] URL: \(url.absoluteString)")
        
        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("🔍 [노트 분석 API 응답] 상태 코드: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [노트 분석 API 오류] \(httpResponse.statusCode): \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let noteResponse = try decoder.decode(NoteAnalysisResponse.self, from: data)
        
        print("✅ [노트 분석 API 성공] 향수 인덱스: \(perfumeIndex)")
        return noteResponse
    }
    
    // MARK: - 시스템 상태 API
    
    func getSystemStatus() async throws -> SystemStatusResponse {
        let url = URL(string: "\(baseURL)/perfumes/system-status")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 30.0
        
        print("🚀 [시스템 상태 API 요청] URL: \(url.absoluteString)")
        
        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("🔍 [시스템 상태 API 응답] 상태 코드: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [시스템 상태 API 오류] \(httpResponse.statusCode): \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let statusResponse = try decoder.decode(SystemStatusResponse.self, from: data)
        
        print("✅ [시스템 상태 API 성공] 상태: \(statusResponse.status)")
        return statusResponse
    }
    
    // MARK: - CSV 정보 API
    
    func getCSVInfo() async throws -> CSVInfoResponse {
        let url = URL(string: "\(baseURL)/perfumes/debug/csv-info")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 30.0
        
        print("🚀 [CSV 정보 API 요청] URL: \(url.absoluteString)")
        
        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("🔍 [CSV 정보 API 응답] 상태 코드: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [CSV 정보 API 오류] \(httpResponse.statusCode): \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let csvResponse = try decoder.decode(CSVInfoResponse.self, from: data)
        
        print("✅ [CSV 정보 API 성공] 총 행 수: \(csvResponse.info.total_rows)")
        return csvResponse
    }
    
    // MARK: - 2차 추천 점수 저장 API
    
    func saveRecommendations(userId: String, recommendRound: Int, recommendations: [PerfumeRecommendationItem]) async throws {
        let url = URL(string: "\(baseURL)/recommendations/save")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30.0
        
        let requestBody = SaveRecommendationsRequest(
            userId: userId,
            recommendRound: recommendRound,
            recommendations: recommendations
        )
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(requestBody)
        
        print("🚀 [추천 저장 API 요청] URL: \(url.absoluteString)")
        if let bodyData = urlRequest.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            print("   Body: \(bodyString)")
        }
        
        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            print("❌ [추천 저장 API] 응답을 HTTPURLResponse로 변환할 수 없음")
            throw URLError(.badServerResponse)
        }
        
        print("🔍 [추천 저장 API 응답] 상태 코드: \(httpResponse.statusCode)")
        
        // 응답 내용을 항상 출력 (성공/실패 관계없이)
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 [추천 저장 API 응답] Body: \(responseString)")
        }
        
        // 상태 코드별 상세 처리
        switch httpResponse.statusCode {
        case 200:
            print("✅ [추천 저장 API 성공] \(recommendations.count)개 추천 저장됨")
        case 400:
            print("❌ [추천 저장 API] 잘못된 요청 (400)")
            throw URLError(.badURL)
        case 401:
            print("❌ [추천 저장 API] 인증 오류 (401)")
            throw URLError(.userAuthenticationRequired)
        case 404:
            print("❌ [추천 저장 API] 엔드포인트를 찾을 수 없음 (404)")
            throw URLError(.fileDoesNotExist)
        case 422:
            print("❌ [추천 저장 API] 유효성 검사 실패 (422)")
            throw URLError(.dataNotAllowed)
        case 500...599:
            print("❌ [추천 저장 API] 서버 내부 오류 (\(httpResponse.statusCode))")
            throw URLError(.badServerResponse)
        default:
            print("❌ [추천 저장 API] 예상하지 못한 상태 코드: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - 향수 노트 정보 조회 (2차 추천용)
    
    func getPerfumeNotes(perfumeName: String) async throws -> PerfumeNotes {
        do {
            let perfume = try await fetchPerfumeDetail(name: perfumeName)
            return perfume.notes
        } catch {
            return PerfumeNotes(top: [], middle: [], base: [])
        }
    }
    
    // MARK: - 향수 인덱스로 향수 정보 조회
    
    func fetchPerfumeByIndex(_ index: Int) async throws -> Perfume {
        print("🔍 [향수 인덱스 조회] 인덱스: \(index)")
        
        // 재시도 로직 (최대 3회)
        for attempt in 1...3 {
            do {
                print("🚀 [향수 인덱스 API] 시도 \(attempt)/3")
                
                let url = URL(string: "\(baseURL)/perfumes/by-index/\(index)")!
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = "GET"
                urlRequest.timeoutInterval = 45.0  // 15초 → 45초로 증가
                
                // 캐싱 방지 헤더 추가
                let requestId = UUID().uuidString
                urlRequest.setValue(requestId, forHTTPHeaderField: "X-Request-ID")
                urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                
                print("   URL: \(url.absoluteString) (타임아웃: 45초)")
                
                let (data, response) = try await URLSession.shared.data(for: urlRequest)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 [향수 인덱스 API] 응답 코드: \(httpResponse.statusCode)")
                    
                    guard httpResponse.statusCode == 200 else {
                        if let errorString = String(data: data, encoding: .utf8) {
                            print("❌ [향수 인덱스 API 오류] \(httpResponse.statusCode): \(errorString)")
                        }
                        throw URLError(.badServerResponse)
                    }
                }
                
                let decoder = JSONDecoder()
                
                // 먼저 APIResponse 래퍼로 시도
                do {
                    let apiResponse = try decoder.decode(APIResponse<PerfumeDetailResponseData>.self, from: data)
                    let perfume = apiResponse.data.toPerfume()
                    print("✅ [향수 인덱스 조회 성공] (APIResponse) \(perfume.brand) - \(perfume.name)")
                    print("🖼️ [이미지 URL] '\(perfume.imageURL)'")
                    
                    // 이미지 URL 유효성 검증
                    if perfume.imageURL.isEmpty || perfume.imageURL == "string" {
                        print("⚠️ [이미지 URL 문제] 빈 URL 또는 기본값 감지, 안전한 URL로 교체")
                        let safeURL = generateSafeImageURL(for: perfume.name, brand: perfume.brand, index: index)
                        return Perfume(id: perfume.id, name: perfume.name, brand: perfume.brand, imageURL: safeURL, price: perfume.price, description: perfume.description, notes: perfume.notes, rating: perfume.rating, emotionTags: perfume.emotionTags, similarity: perfume.similarity)
                    }
                    
                    return perfume
                } catch {
                    print("⚠️ [APIResponse 디코딩 실패] 직접 디코딩 시도: \(error)")
                    
                    // 직접 PerfumeDetailResponseData로 디코딩 시도
                    do {
                        let perfumeData = try decoder.decode(PerfumeDetailResponseData.self, from: data)
                        let perfume = perfumeData.toPerfume()
                        print("✅ [향수 인덱스 조회 성공] (직접) \(perfume.brand) - \(perfume.name)")
                        print("🖼️ [이미지 URL] '\(perfume.imageURL)'")
                        
                        // 이미지 URL 유효성 검증
                        if perfume.imageURL.isEmpty || perfume.imageURL == "string" {
                            print("⚠️ [이미지 URL 문제] 빈 URL 또는 기본값 감지, 안전한 URL로 교체")
                            let safeURL = generateSafeImageURL(for: perfume.name, brand: perfume.brand, index: index)
                            return Perfume(id: perfume.id, name: perfume.name, brand: perfume.brand, imageURL: safeURL, price: perfume.price, description: perfume.description, notes: perfume.notes, rating: perfume.rating, emotionTags: perfume.emotionTags, similarity: perfume.similarity)
                        }
                        
                        return perfume
                    } catch {
                        print("❌ [직접 디코딩도 실패] \(error)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("🔍 [응답 내용] \(responseString)")
                        }
                        throw error
                    }
                }
                
            } catch {
                print("❌ [향수 인덱스 API] 시도 \(attempt) 실패: \(error)")
                
                // 타임아웃인 경우 특별 처리
                if let urlError = error as? URLError, urlError.code == .timedOut {
                    print("⏰ [타임아웃 감지] Render 서버 Cold Start 가능성")
                }
                
                // 마지막 시도가 아니면 재시도 전 대기
                if attempt < 3 {
                    let waitTime = attempt * 2  // 2초, 4초, 6초
                    print("⏳ [재시도 대기] \(waitTime)초 후 재시도...")
                    try? await Task.sleep(nanoseconds: UInt64(waitTime) * 1_000_000_000)
                }
            }
        }
        
        print("❌ [향수 인덱스 API] 모든 시도 실패")
        
        // 폴백 1: 전체 목록에서 찾기 (타임아웃 늘려서)
        do {
            print("🔄 [폴백 1] 전체 향수 목록에서 인덱스 \(index) 찾기")
            let allPerfumes = try await fetchPerfumesWithRetry()
            if index < allPerfumes.count {
                let perfume = allPerfumes[index]
                print("✅ [폴백 1 성공] \(perfume.brand) - \(perfume.name)")
                return perfume
            } else {
                print("❌ [폴백 1 실패] 인덱스 \(index)가 범위를 벗어남 (총 \(allPerfumes.count)개)")
            }
        } catch {
            print("❌ [폴백 1 실패] \(error)")
        }
        
        // 폴백 2: 로컬 현실적인 향수 데이터
        print("🔄 [폴백 2] 로컬 현실적인 향수 데이터 사용")
        let realisticPerfumes = PerfumeDataUtils.createRealisticPerfumes()
        if !realisticPerfumes.isEmpty {
            let perfumeIndex = index % realisticPerfumes.count
            let fallbackPerfume = realisticPerfumes[perfumeIndex]
            print("✅ [폴백 2 성공] \(fallbackPerfume.brand) - \(fallbackPerfume.name)")
            return fallbackPerfume
        }
        
        // 폴백 3: 안전한 기본 향수 생성
        print("🔄 [폴백 3] 안전한 기본 향수 생성")
        let safeImageURL = generateSafeImageURL(for: "향수", brand: "브랜드", index: index)
        return Perfume(
            id: "perfume_\(index)",
            name: "향수 #\(index)",
            brand: "브랜드",
            imageURL: safeImageURL,
            price: 0.0,
            description: "AI 추천 향수입니다.",
            notes: PerfumeNotes(top: [], middle: [], base: []),
            rating: 4.0,
            emotionTags: ["AI 추천"],
            similarity: 0.0
        )
    }
    
    // 재시도 로직이 포함된 향수 목록 조회
    private func fetchPerfumesWithRetry() async throws -> [Perfume] {
        for attempt in 1...2 {  // 2회만 시도 (너무 많이 하면 오래 걸림)
            do {
                print("🚀 [향수 목록 API] 시도 \(attempt)/2")
                
                let url = URL(string: "\(baseURL)/perfumes/")!
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = "GET"
                urlRequest.timeoutInterval = 60.0  // 30초 → 60초로 증가
                
                let (data, _) = try await URLSession.shared.data(for: urlRequest)
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(APIResponse<PerfumesData>.self, from: data)
                
                print("✅ [향수 목록 API 성공] \(apiResponse.data.perfumes.count)개 향수")
                return apiResponse.data.perfumes.map { $0.toPerfume() }
                
            } catch {
                print("❌ [향수 목록 API] 시도 \(attempt) 실패: \(error)")
                
                if attempt < 2 {
                    print("⏳ [재시도 대기] 3초 후 재시도...")
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                }
            }
        }
        
        throw URLError(.unknown)
    }
    
    // 안정한 이미지 URL 생성 헬퍼 함수
    private func generateSafeImageURL(for name: String, brand: String, index: Int) -> String {
        // 향수 이름과 브랜드를 조합하여 일관된 시드 생성
        let combined = "\(brand)\(name)".lowercased().replacingOccurrences(of: " ", with: "")
        let seed = abs(combined.hashValue) % 1000 + 1
        
        // Picsum을 사용하되, 향수 관련 키워드로 더 관련성 있는 이미지
        // 200x300은 향수병 비율에 적합
        return "https://picsum.photos/200/300?random=\(seed + index)"
    }
    
    // MARK: - 시향 일기 API
    
    /// 이미지 업로드 (단독)
    func uploadDiaryImage(_ image: UIImage) async throws -> String {
        let url = URL(string: "\(baseURL)/diaries/upload-image")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 60.0 // 이미지 업로드는 더 긴 시간 필요
        
        // 이미지를 JPEG로 변환
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.encodingError
        }
        
        // multipart/form-data 형태로 전송
        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"diary_image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        urlRequest.httpBody = body
        
        print("📸 [이미지 업로드] 백엔드 API 요청 시작")
        print("📏 [이미지 크기] \(imageData.count) bytes")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📊 [이미지 업로드] 응답 코드: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ [이미지 업로드 오류] \(httpResponse.statusCode): \(errorString)")
                }
                throw NetworkError.serverError
            }
        }
        
        // 응답에서 이미지 URL 추출
        if let responseString = String(data: data, encoding: .utf8) {
            print("✅ [이미지 업로드 성공] 응답: \(responseString)")
            
            // JSON 형태의 응답 파싱
            if let jsonData = responseString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let imageUrl = json["image_url"] as? String {
                return imageUrl
            }
            
            // 단순 URL 응답인 경우
            return responseString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        throw NetworkError.decodingError
    }
    
    /// 시향 일기 + 이미지 동시 작성
    func createScentDiaryWithImage(_ request: ScentDiaryRequest, image: UIImage) async throws -> ScentDiaryModel {
        let url = URL(string: "\(baseURL)/diaries/with-image")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 60.0
        
        // 이미지를 JPEG로 변환
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.encodingError
        }
        
        // multipart/form-data 형태로 전송
        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 시향 일기 데이터 추가
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(request.userId)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"perfume_name\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(request.perfumeName)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"content\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(request.content)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"is_public\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(request.isPublic)\r\n".data(using: .utf8)!)
        
        // emotion_tags는 이미 JSON 문자열이므로 직접 추가
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"emotion_tags\"\r\n\r\n".data(using: .utf8)!)
        body.append(request.emotionTags.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // 이미지 데이터 추가
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"diary_image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        urlRequest.httpBody = body
        
        print("🚀 [시향 일기+이미지 작성] 백엔드 API 요청 시작")
        print("📝 [요청 데이터] 향수: \(request.perfumeName), 사용자: \(request.userId)")
        print("📸 [이미지 크기] \(imageData.count) bytes")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📊 [시향 일기+이미지 작성] 응답 코드: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ [시향 일기+이미지 작성 오류] \(httpResponse.statusCode): \(errorString)")
                }
                throw NetworkError.serverError
            }
        }
        
                    let decoder = JSONDecoder()
            
            // 🔍 백엔드 응답 내용 로그 (디버깅용)
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 [시향일기+이미지 백엔드 응답 원본]:")
                print("=== 응답 시작 ===")
                print(responseString)
                print("=== 응답 끝 ===")
            }
            
            // APIResponse 래퍼로 감싸져 있는지 확인
            do {
                let apiResponse = try decoder.decode(APIResponse<ScentDiaryModel>.self, from: data)
                print("✅ [시향 일기+이미지 작성 성공] ID: \(apiResponse.data.id)")
                return apiResponse.data
            } catch {
                // 직접 ScentDiaryModel로 디코딩 시도
                let diaryEntry = try decoder.decode(ScentDiaryModel.self, from: data)
                print("✅ [시향 일기+이미지 작성 성공] ID: \(diaryEntry.id)")
                return diaryEntry
            }
    }
    
    /// 시향 일기 작성 (텍스트만)
    func createScentDiary(_ request: ScentDiaryRequest) async throws -> ScentDiaryModel {
        let url = URL(string: "\(baseURL)/diaries/")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30.0
        
        do {
            let requestData = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestData
            
            print("🚀 [시향 일기 작성] API 요청 시작")
            print("📝 [요청 데이터] 향수: \(request.perfumeName), 사용자: \(request.userId)")
            if let imageUrl = request.imageUrl {
                print("📸 [이미지 포함] URL: \(imageUrl)")
            }
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 [시향 일기 작성] 응답 코드: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("❌ [시향 일기 작성 오류] \(httpResponse.statusCode): \(errorString)")
                    }
                    throw NetworkError.serverError
                }
            }
            
            let decoder = JSONDecoder()
            
            // 🔍 백엔드 응답 내용 로그 (디버깅용)
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 [시향일기 백엔드 응답 원본]:")
                print("=== 응답 시작 ===")
                print(responseString)
                print("=== 응답 끝 ===")
            }
            
            // APIResponse 래퍼로 감싸져 있는지 확인
            do {
                let apiResponse = try decoder.decode(APIResponse<ScentDiaryModel>.self, from: data)
                print("✅ [시향 일기 작성 성공] ID: \(apiResponse.data.id)")
                return apiResponse.data
            } catch {
                // 직접 ScentDiaryModel로 디코딩 시도
                let diaryEntry = try decoder.decode(ScentDiaryModel.self, from: data)
                print("✅ [시향 일기 작성 성공] ID: \(diaryEntry.id)")
                return diaryEntry
            }
            
        } catch {
            print("❌ [시향 일기 작성 실패] \(error)")
            throw error
        }
    }
    
    /// 시향 일기 목록 조회
    func fetchScentDiaries(userId: String? = nil) async throws -> [ScentDiaryModel] {
        var urlComponents = URLComponents(string: "\(baseURL)/diaries/")!
        
        // userId가 있으면 쿼리 파라미터로 추가
        if let userId = userId {
            urlComponents.queryItems = [URLQueryItem(name: "user_id", value: userId)]
        }
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 30.0
        
        do {
            print("🚀 [시향 일기 목록 조회] API 요청 시작")
            if let userId = userId {
                print("👤 [사용자 조건] \(userId)")
            } else {
                print("📄 [전체 목록] 모든 사용자")
            }
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 [시향 일기 목록 조회] 응답 코드: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("❌ [시향 일기 목록 조회 오류] \(httpResponse.statusCode): \(errorString)")
                    }
                    throw NetworkError.serverError
                }
            }
            
            let decoder = JSONDecoder()
            
            // 🔍 백엔드 응답 내용 로그 (디버깅용)
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 [일기목록 백엔드 응답 원본]:")
                print("=== 응답 시작 ===")
                print(responseString)
                print("=== 응답 끝 ===")
            }
            
            // 다양한 응답 형태 시도 (조용히)
            
            // 1. 백엔드 API 응답 구조 (result 래퍼)
            if let backendResponse = try? decoder.decode(ScentDiaryBackendResponse.self, from: data) {
                print("✅ [시향 일기 목록 조회 성공] 백엔드 API 응답 구조: \(backendResponse.result.diaries.count)개 일기")
                // 각 일기의 content와 tags 로그
                for (index, diary) in backendResponse.result.diaries.enumerated() {
                    print("📋 [일기 \(index+1)] ID: \(diary.id)")
                    print("📋 [일기 \(index+1)] content: '\(diary.content)'")
                    print("📋 [일기 \(index+1)] tags: \(diary.tags)")
                }
                return backendResponse.result.diaries
            }
            
            // 2. 직접 배열 형태 (가장 일반적)
            if let diaryEntries = try? decoder.decode([ScentDiaryModel].self, from: data) {
                print("✅ [시향 일기 목록 조회 성공] 직접 배열 형태: \(diaryEntries.count)개 일기")
                // 각 일기의 content와 tags 로그
                for (index, diary) in diaryEntries.enumerated() {
                    print("📋 [일기 \(index+1)] ID: \(diary.id)")
                    print("📋 [일기 \(index+1)] content: '\(diary.content)'")
                    print("📋 [일기 \(index+1)] tags: \(diary.tags)")
                }
                return diaryEntries
            }
            
            // 3. ScentDiaryListResponse 래퍼
            if let diaryListResponse = try? decoder.decode(ScentDiaryListResponse.self, from: data) {
                print("✅ [시향 일기 목록 조회 성공] ScentDiaryListResponse 래퍼: \(diaryListResponse.diaries.count)개 일기")
                return diaryListResponse.diaries
            }
            
            // 4. APIResponse<[ScentDiaryModel]> 래퍼
            if let apiResponse = try? decoder.decode(APIResponse<[ScentDiaryModel]>.self, from: data) {
                print("✅ [시향 일기 목록 조회 성공] APIResponse+Array 래퍼: \(apiResponse.data.count)개 일기")
                return apiResponse.data
            }
            
            // 5. APIResponse<ScentDiaryListResponse> 래퍼
            if let apiResponse = try? decoder.decode(APIResponse<ScentDiaryListResponse>.self, from: data) {
                print("✅ [시향 일기 목록 조회 성공] APIResponse+ScentDiaryListResponse: \(apiResponse.data.diaries.count)개 일기")
                return apiResponse.data.diaries
            }
            
            // 6. 빈 딕셔너리나 다른 딕셔너리 응답 처리
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("🔍 [딕셔너리 응답 감지] 빈 딕셔너리 또는 다른 형태")
                    print("✅ [시향 일기 목록 조회 성공] 딕셔너리 응답: 0개 일기 (빈 목록)")
                    return []
                }
            } catch {
                // JSONSerialization 실패 시 무시하고 계속 진행
            }
            
            // 모든 디코딩 시도 실패 - 응답 내용 확인
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ [시향 일기 목록 조회] 모든 디코딩 형태 실패")
                print("🔍 [응답 내용] \(responseString.prefix(500))...")
                
                // 응답이 비어있는지 확인
                if responseString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    print("📭 [빈 응답] 응답이 비어있음, 빈 배열 반환")
                    return []
                }
                
                // JSON이 아닌 경우 확인
                if !responseString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") && 
                   !responseString.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[") {
                    print("❌ [비JSON 응답] JSON 형태가 아님")
                    return []
                }
            }
            
            // 빈 배열 반환 (폴백)
            print("🔄 [폴백] 빈 배열 반환")
            return []
            
        } catch {
            print("❌ [시향 일기 목록 조회 실패] \(error)")
            throw error
        }
    }
}

struct Store: Codable, Identifiable {
    let storeName: String
    let brand: String
    let lat: Double
    let lon: Double
    let address: String
    
    var id: String { storeName }
    
    enum CodingKeys: String, CodingKey {
        case storeName = "store_name"
        case brand
        case lat
        case lon
        case address
    }
}

enum NetworkError: Error {
    case invalidResponse
    case invalidData
    case decodingError
    case encodingError
    case invalidURL
    case notFound
    case serverError
    case unknown
} 
