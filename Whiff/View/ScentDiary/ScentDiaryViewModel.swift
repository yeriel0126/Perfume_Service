import Foundation
import SwiftUI
import Combine

@MainActor
class ScentDiaryViewModel: ObservableObject {
    @Published var diaries: [ScentDiaryModel] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    
    private let networkManager = NetworkManager.shared
    private let apiClient = APIClient.shared
    
    // 좋아요 상태를 저장하는 딕셔너리
    @Published private var likedDiaries: Set<String> = []
    
    init() {
        Task {
            await fetchDiaries()
            _ = loadLocalDiaries() // 반환값을 사용하지 않으므로 _ = ... 으로 변경
        }
    }
    
    // 시간순으로 정렬된 일기 목록 (공개 게시물만)
    var sortedDiaries: [ScentDiaryModel] {
        diaries.filter { $0.isPublic }.sorted { $0.createdAt > $1.createdAt }
    }
    
    // 모든 일기 (공개 + 비공개) - 프로필용
    var allSortedDiaries: [ScentDiaryModel] {
        diaries.sorted { $0.createdAt > $1.createdAt }
    }
    
    // 특정 일기의 좋아요 상태 확인
    func isLiked(_ diaryId: String) -> Bool {
        likedDiaries.contains(diaryId)
    }
    
    // MARK: - 백엔드 API 연동 메서드
    
    /// 시향 일기 목록 조회 (백엔드 + 로컬)
    func fetchDiaries(userId: String? = nil) async {
        print("🔄 [ScentDiaryViewModel] 시향 일기 목록 조회 시작")
        isLoading = true
        error = nil
        
        var allDiaries: [ScentDiaryModel] = []
        
        // 1. 백엔드에서 데이터 조회 시도
        do {
            let backendDiaries = try await networkManager.fetchScentDiaries(userId: userId)
            allDiaries.append(contentsOf: backendDiaries)
            print("🌐 [ScentDiaryViewModel] 백엔드 시향 일기 조회 성공: \(backendDiaries.count)개")
        } catch {
            print("❌ [ScentDiaryViewModel] 백엔드 시향 일기 조회 실패: \(error)")
            
            // 502 에러의 경우 더 친화적인 메시지 제공
            if let apiError = error as? APIError, apiError.localizedDescription.contains("502") {
                self.error = APIError.serverError("현재 서버가 일시적으로 응답하지 않습니다. 잠시 후 다시 시도해주세요.")
            } else {
                self.error = error
            }
        }
        
        // 2. 로컬 데이터는 백엔드 실패 시에만 로드
        if allDiaries.isEmpty {
            let localDiaries = loadLocalDiaries()
            allDiaries.append(contentsOf: localDiaries)
            print("📄 [ScentDiaryViewModel] 백엔드 실패로 로컬 시향 일기 로드: \(localDiaries.count)개")
        } else {
            print("📄 [ScentDiaryViewModel] 백엔드 데이터 있음, 로컬 데이터 건너뜀")
        }
        
        // 3. 중복 제거 (ID 기준)
        var uniqueDiaries: [ScentDiaryModel] = []
        var seenIds: Set<String> = []
        
        for diary in allDiaries {
            if !seenIds.contains(diary.id) {
                uniqueDiaries.append(diary)
                seenIds.insert(diary.id)
            }
        }
        
        // 4. 날짜순 정렬
        diaries = uniqueDiaries.sorted { $0.createdAt > $1.createdAt }
        print("✅ [ScentDiaryViewModel] 전체 시향 일기 조회 완료: \(diaries.count)개 (중복 제거 후)")
        
        // 5. 목업 데이터는 백엔드에 데이터가 없을 때만 추가
        if diaries.isEmpty {
            await loadMockDataIfNeeded()
        }
        
        // 6. 디버깅 정보 출력
        debugLocalData()
        
        isLoading = false
    }
    
    /// 시향 일기 작성 (백엔드 API)
    func createDiary(
        userId: String,
        perfumeName: String,
        content: String,
        isPublic: Bool = false,
        emotionTags: [String],
        selectedImage: UIImage? = nil
    ) async -> Bool {
        isLoading = true
        error = nil
        
        print("🔄 [ScentDiaryViewModel] 시향 일기 작성 시작")
        print("   - 사용자 ID: '\(userId)'")
        print("   - 향수명: '\(perfumeName)'")
        print("   - 내용 길이: \(content.count)자")
        print("   - 내용 내용: '\(content)'")
        print("   - 태그: \(emotionTags)")
        print("   - 공개 여부: \(isPublic)")
        print("   - 이미지 포함: \(selectedImage != nil)")
        
        // 현재 사용자 정보 가져오기 (여러 키 시도)
        let userName = UserDefaults.standard.string(forKey: "currentUserName") ??
                      UserDefaults.standard.string(forKey: "userName") ?? "사용자"
        let userProfileImage = UserDefaults.standard.string(forKey: "currentUserProfileImage") ??
                              UserDefaults.standard.string(forKey: "userProfileImage") ?? ""
        
        print("👤 [사용자 정보 확인] 사용자 ID: \(userId)")
        print("👤 [사용자 정보 확인] 사용자 이름: \(userName)")
        print("👤 [사용자 정보 확인] 프로필 이미지: \(userProfileImage)")
        
        // 백엔드 API 요청 생성 (감정 태그를 JSON 문자열로 변환)
        let request = ScentDiaryRequest(
            userId: userId,
            perfumeName: perfumeName,
            content: content,
            isPublic: isPublic,
            emotionTagsArray: emotionTags,
            imageUrl: nil // 이미지는 별도로 처리
        )
        
        print("🔍 [백엔드 요청] ScentDiaryRequest:")
        print("   - userId: \(request.userId)")
        print("   - perfumeName: \(request.perfumeName)")
        print("   - content: \(request.content)")
        print("   - isPublic: \(request.isPublic)")
        print("   - emotionTags (JSON): \(request.emotionTags)")
        print("   - imageUrl: \(request.imageUrl ?? "nil")")
        
        var backendSuccess = false
        var createdDiary: ScentDiaryModel?
        
        do {
            if let image = selectedImage {
                // 이미지가 있는 경우: /diaries/with-image 엔드포인트 사용
                print("🚀 [백엔드 API] 시향 일기+이미지 동시 저장 요청...")
                createdDiary = try await networkManager.createScentDiaryWithImage(request, image: image)
                print("✅ [백엔드 API] 시향 일기+이미지 저장 성공")
            } else {
                // 이미지가 없는 경우: /diaries/ 엔드포인트 사용
                print("🚀 [백엔드 API] 시향 일기 저장 요청...")
                createdDiary = try await networkManager.createScentDiary(request)
                print("✅ [백엔드 API] 시향 일기 저장 성공")
            }
            
            backendSuccess = true
            
            if let diary = createdDiary {
                print("✅ [백엔드 성공] 일기 ID: \(diary.id)")
                print("✅ [백엔드 성공] 사용자: \(diary.userName), 향수: \(diary.perfumeName)")
                print("✅ [백엔드 성공] 내용: \(diary.content.prefix(50))...")
                print("✅ [백엔드 성공] 태그: \(diary.emotionTags)")
                print("✅ [백엔드 성공] 이미지: \(diary.imageUrl ?? "없음")")
                print("🔐 [백엔드 성공] 공개 설정: \(diary.isPublic)")
                
                // 백엔드에서 반환된 일기를 메모리에 즉시 추가 (사용자에게 즉시 보여주기 위해)
                await MainActor.run {
                    if !diaries.contains(where: { $0.id == diary.id }) {
                        diaries.insert(diary, at: 0)
                        print("📲 [실시간 업데이트] 새 일기 피드에 추가: \(diary.id)")
                    }
                }
                await addToProfileDiary(diary)
            }
            
        } catch {
            print("❌ [백엔드 API] 시향 일기 저장 실패: \(error)")
            
            // 구체적인 에러 정보 출력
            if let apiError = error as? APIError {
                print("❌ [API Error] 타입: \(apiError)")
                print("❌ [API Error] 설명: \(apiError.localizedDescription)")
            } else if let networkError = error as? NetworkError {
                print("❌ [Network Error] 타입: \(networkError)")
                print("❌ [Network Error] 설명: \(networkError.localizedDescription)")
            } else {
                print("❌ [Unknown Error] 타입: \(type(of: error))")
                print("❌ [Unknown Error] 설명: \(error.localizedDescription)")
            }
            
            // 502 에러나 서버 응답 오류의 경우 더 명확한 메시지
            let errorMessage = error.localizedDescription
            if errorMessage.contains("502") || errorMessage.contains("Bad Gateway") {
                print("🚨 [서버 오류] 502 Bad Gateway - 서버가 일시적으로 응답하지 않습니다")
                self.error = APIError.serverError("서버가 일시적으로 응답하지 않습니다. 잠시 후 다시 시도해주세요.")
            } else if errorMessage.contains("timeout") || errorMessage.contains("network") {
                print("🚨 [네트워크 오류] 연결 시간 초과 또는 네트워크 문제")
                self.error = APIError.networkError(error)
            }
            
            print("🔄 [폴백] 로컬 저장 진행...")
            
            // 백엔드 실패 시 로컬에 저장 (폴백)
            var imageUrl: String? = nil
            if let image = selectedImage {
                print("📸 [폴백] 로컬 이미지 저장...")
                imageUrl = await uploadImageLocal(image)
                print("📸 [폴백] 로컬 이미지 저장 완료: \(imageUrl ?? "실패")")
            }
            
            let fallbackDiary = ScentDiaryModel(
                id: UUID().uuidString,
                userId: userId,
                userName: userName,
                userProfileImage: userProfileImage,
                perfumeId: nil,
                perfumeName: perfumeName,
                brand: nil,
                content: content,
                tags: emotionTags,
                likes: 0,
                comments: 0,
                isPublic: isPublic,
                imageUrl: imageUrl,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            print("🔍 [폴백 일기 생성] 상세 정보:")
            print("   - 사용자 ID: '\(userId)'")
            print("   - 사용자 이름: '\(userName)'")
            print("   - 향수명: '\(perfumeName)'")
            print("   - 내용: '\(content)'")
            print("   - 태그 배열: \(emotionTags)")
            print("   - 공개 여부: \(isPublic)")
            print("   - 이미지 URL: \(imageUrl ?? "없음")")
            
            print("✅ [폴백] 일기 생성: \(fallbackDiary.id)")
            print("✅ [폴백] 사용자: \(userName), 향수: \(perfumeName)")
            print("✅ [폴백] 내용: \(content.prefix(50))...")
            print("✅ [폴백] 태그: \(emotionTags)")
            print("✅ [폴백] 이미지: \(imageUrl ?? "없음")")
            print("🔐 [폴백] 공개 설정: \(isPublic)")
            
            // 폴백 시에도 피드에 즉시 추가
            await MainActor.run {
                if !diaries.contains(where: { $0.id == fallbackDiary.id }) {
                    diaries.insert(fallbackDiary, at: 0)
                    print("📲 [폴백 실시간 업데이트] 새 일기 피드에 추가: \(fallbackDiary.id)")
                }
            }
            
            // 폴백 시에만 로컬 저장
            await addToProfileDiary(fallbackDiary)
            await saveLocalDiary(fallbackDiary)
            print("✅ [폴백] 로컬 저장 완료")
        }
        
        isLoading = false
        
        // 백엔드 성공 여부와 관계없이 항상 true 반환 (사용자에게는 성공으로 보여줌)
        print("✅ [ScentDiaryViewModel] 시향 일기 작성 완료 (백엔드: \(backendSuccess ? "성공" : "실패->로컬저장"))")
        return true
    }
    
    /// 프로필 일기 관리에 시향 일기 추가
    private func addToProfileDiary(_ diary: ScentDiaryModel) async {
        print("📝 [프로필 연동] 일기 관리에 추가...")
        
        // UserDefaults에서 기존 일기 목록 로드
        var diaryEntries: [DiaryEntry] = []
        if let data = UserDefaults.standard.data(forKey: "diaryEntries"),
           let entries = try? JSONDecoder().decode([DiaryEntry].self, from: data) {
            diaryEntries = entries
            print("📝 [프로필 연동] 기존 일기 \(entries.count)개 로드")
        } else {
            print("📝 [프로필 연동] 기존 일기 없음, 새로 시작")
        }
        
        // 시향 일기를 DiaryEntry 형식으로 변환
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M월 d일"
        let dateString = dateFormatter.string(from: diary.createdAt)
        
        let profileDiary = DiaryEntry(
            id: diary.id,
            title: "\(dateString), 시향 일기",
            content: diary.content,
            date: diary.createdAt,
            mood: getMoodFromTags(diary.tags),
            imageURL: diary.imageUrl ?? ""
        )
        
        // 중복 방지 (이미 같은 ID가 있는지 확인)
        if !diaryEntries.contains(where: { $0.id == profileDiary.id }) {
            diaryEntries.insert(profileDiary, at: 0) // 최신 일기를 맨 앞에 추가
            print("📝 [프로필 연동] 새 일기 추가: \(profileDiary.title)")
            
            // UserDefaults에 저장
            do {
                let data = try JSONEncoder().encode(diaryEntries)
                UserDefaults.standard.set(data, forKey: "diaryEntries")
                UserDefaults.standard.synchronize() // 강제 동기화
                print("✅ [프로필 연동] 일기 관리에 저장 완료 (총 \(diaryEntries.count)개)")
                
                // 프로필 뷰에 업데이트 알림 보내기
                await MainActor.run {
                    NotificationCenter.default.post(name: Notification.Name("DiaryUpdated"), object: nil)
                    print("📢 [프로필 연동] 일기 업데이트 알림 전송")
                }
                
            } catch {
                print("❌ [프로필 연동] 저장 실패: \(error)")
            }
        } else {
            print("⚠️ [프로필 연동] 이미 존재하는 일기 (중복 방지)")
        }
    }
    
    /// 감정 태그에서 기분 이모지 추출
    private func getMoodFromTags(_ tags: [String]) -> String {
        for tag in tags {
            switch tag.lowercased() {
            case let t where t.contains("행복") || t.contains("기쁜") || t.contains("즐거운"):
                return "😊"
            case let t where t.contains("사랑") || t.contains("로맨틱") || t.contains("설레는"):
                return "😍"
            case let t where t.contains("차분") || t.contains("평온") || t.contains("안정"):
                return "😌"
            case let t where t.contains("상쾌") || t.contains("청량") || t.contains("시원"):
                return "😎"
            case let t where t.contains("따뜻") || t.contains("포근") || t.contains("편안"):
                return "🥰"
            case let t where t.contains("신비") || t.contains("매혹") || t.contains("우아"):
                return "🤔"
            case let t where t.contains("활기") || t.contains("에너지") || t.contains("생동"):
                return "😄"
            default:
                continue
            }
        }
        return "😊" // 기본값
    }
    
    /// 이미지 업로드 (로컬 저장 방식 - 폴백용)
    private func uploadImageLocal(_ image: UIImage) async -> String? {
        print("📸 [폴백 이미지 업로드] 로컬 저장 시작...")
        
        // 이미지를 JPEG로 변환
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ [이미지 업로드] JPEG 변환 실패")
            return nil
        }
        
        // Documents 디렉토리에 저장
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask).first!
        let fileName = "diary_image_\(UUID().uuidString).jpg"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            let imageUrl = fileURL.absoluteString
            print("✅ [폴백 이미지 업로드] 로컬 저장 완료: \(fileName)")
            return imageUrl
        } catch {
            print("❌ [폴백 이미지 업로드] 저장 실패: \(error)")
            return nil
        }
    }
    
    /// 특정 사용자의 일기만 조회
    func fetchUserDiaries(userId: String) async {
        await fetchDiaries(userId: userId)
    }
    
    // MARK: - 좋아요 기능 (백엔드 미구현으로 임시 비활성화)
    
    // 좋아요 토글 (백엔드 미구현)
    func toggleLike(_ diaryId: String) async {
        // 백엔드에서 좋아요 API가 구현되지 않아서 임시 비활성화
        print("💡 [좋아요 기능] 백엔드 미구현으로 비활성화됨")
        
        // TODO: 백엔드 API 구현 후 아래 코드 활성화
        /*
        guard let index = diaries.firstIndex(where: { $0.id == diaryId }) else { return }
        
        do {
            if likedDiaries.contains(diaryId) {
                _ = try await apiClient.unlikeDiary(diaryId: diaryId)
                likedDiaries.remove(diaryId)
                diaries[index].likes -= 1
            } else {
                _ = try await apiClient.likeDiary(diaryId: diaryId)
                likedDiaries.insert(diaryId)
                diaries[index].likes += 1
            }
        } catch {
            self.error = error
            self.showError = true
            // 좋아요 상태 롤백
            if likedDiaries.contains(diaryId) {
                likedDiaries.remove(diaryId)
                diaries[index].likes -= 1
            } else {
                likedDiaries.insert(diaryId)
                diaries[index].likes += 1
            }
        }
        */
    }
    
    // MARK: - 감정 태그 추천 기능
    
    /// 감정 태그 추천 (콘텐츠 기반)
    func suggestEmotionTags(for content: String) -> [String] {
        let lowercasedContent = content.lowercased()
        var suggestedTags: [String] = []
        
        // 간단한 키워드 기반 감정 태그 추천
        let emotionKeywords: [String: [String]] = [
            "차분": ["평온", "차분", "안정", "고요", "휴식"],
            "행복": ["기쁜", "행복", "즐거운", "좋은", "멋진"],
            "로맨틱": ["로맨틱", "사랑", "데이트", "연인", "낭만"],
            "상쾌": ["상쾌", "신선", "깨끗", "시원", "청량"],
            "따뜻": ["따뜻", "포근", "아늑", "편안", "온화"],
            "활기": ["활기", "에너지", "생동감", "활발", "역동"],
            "봄": ["봄", "벚꽃", "꽃", "새싹", "따뜻한"],
            "여름": ["여름", "더위", "바다", "휴가", "시원한"],
            "가을": ["가을", "단풍", "선선", "포근한", "나뭇잎"],
            "겨울": ["겨울", "추위", "눈", "따뜻한", "포근한"]
        ]
        
        for (emotion, keywords) in emotionKeywords {
            if keywords.contains(where: { lowercasedContent.contains($0) }) {
                suggestedTags.append(emotion)
            }
        }
        
        // 중복 제거 및 최대 3개까지만 반환
        return Array(Set(suggestedTags)).prefix(3).map { $0 }
    }
    
    // MARK: - 유틸리티 함수
    
    /// 에러 메시지를 초기화합니다
    func clearError() {
        error = nil
        showError = false
    }
    
    /// 날짜를 읽기 쉬운 형태로 포맷팅합니다
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current
        
        // 오늘인지 확인 (수동 구현)
        if calendar.isDate(date, inSameDayAs: now) {
            formatter.dateFormat = "HH:mm"
            return "오늘 \(formatter.string(from: date))"
        }
        
        // 어제인지 확인 (수동 구현)
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            formatter.dateFormat = "HH:mm"
            return "어제 \(formatter.string(from: date))"
        }
        
        // 이번 주인지 확인
        if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            formatter.dateFormat = "EEEE HH:mm"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - 폴백 및 목업 데이터
    
    /// 백엔드 API 실패시 목업 데이터 로드
    private func loadMockDataIfNeeded() async {
                    // 목업 데이터가 이미 있는지 확인 (중복 방지)
        let hasMockData = diaries.contains { ["1", "2", "3", "4", "5"].contains($0.id) }
        
        if !hasMockData {
            let mockDiaries = createMockData()
            
            // 기존 일기와 합치기 (중복 ID 제거)
            var seenIds: Set<String> = Set(diaries.map { $0.id })
            for mockDiary in mockDiaries {
                if !seenIds.contains(mockDiary.id) {
                    diaries.append(mockDiary)
                    seenIds.insert(mockDiary.id)
                }
            }
            
            // 다시 날짜순 정렬
            diaries = diaries.sorted { $0.createdAt > $1.createdAt }
            
            print("📄 [목업 데이터] 추가 완료. 전체 일기: \(diaries.count)개")
        }
    }
    
    /// 목업 데이터 생성 (백엔드 API 실패시 폴백용)
    private func createMockData() -> [ScentDiaryModel] {
        let mockDiaries = [
            ScentDiaryModel(
                id: "1",
                userId: "user1",
                userName: "향수 애호가",
                userProfileImage: "https://picsum.photos/100/100?random=10",
                perfumeId: "perfume1",
                perfumeName: "블루 드 샤넬",
                brand: "샤넬",
                content: "오늘은 특별한 날이라 @블루 드 샤넬 을 뿌렸어요. 상쾌한 시트러스 노트가 하루를 시작하는데 좋은 에너지를 줍니다.",
                tags: ["신나는", "상쾌한", "시트러스"],
                likes: 15,
                comments: 3,
                isPublic: true,
                imageUrl: "https://picsum.photos/400/600?random=1",
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date().addingTimeInterval(-3600)
            ),
            ScentDiaryModel(
                id: "2",
                userId: "user2",
                userName: "향수 수집가",
                userProfileImage: "https://picsum.photos/100/100?random=20",
                perfumeId: "perfume2",
                perfumeName: "미스 디올",
                brand: "디올",
                content: "@미스 디올 의 우아한 플로럴 노트가 오늘의 데이트를 더 특별하게 만들어줬어요.",
                tags: ["로맨틱", "플로럴", "우아한"],
                likes: 23,
                comments: 5,
                isPublic: true,
                imageUrl: "https://picsum.photos/400/600?random=2",
                createdAt: Date().addingTimeInterval(-7200),
                updatedAt: Date().addingTimeInterval(-7200)
            ),
            ScentDiaryModel(
                id: "3",
                userId: "user3",
                userName: "향수 매니아",
                userProfileImage: "https://picsum.photos/100/100?random=30",
                perfumeId: "perfume3",
                perfumeName: "블랙 오피엄",
                brand: "YSL",
                content: "@블랙 오피엄 의 깊이 있는 우드 노트가 밤의 분위기를 더욱 매력적으로 만들어줍니다.",
                tags: ["깊이있는", "우드", "밤"],
                likes: 18,
                comments: 2,
                isPublic: true,
                imageUrl: "https://picsum.photos/400/600?random=3",
                createdAt: Date().addingTimeInterval(-10800),
                updatedAt: Date().addingTimeInterval(-10800)
            ),
            ScentDiaryModel(
                id: "4",
                userId: "user4",
                userName: "향수 초보",
                userProfileImage: "https://picsum.photos/100/100?random=40",
                perfumeId: "perfume4",
                perfumeName: "플라워 바이 겐조",
                brand: "겐조",
                content: "처음으로 @플라워 바이 겐조 를 시향해봤는데 진짜 꽃향기 같아요! 봄이 생각나는 상쾌한 느낌입니다. 💐",
                tags: ["봄", "꽃향기", "상쾌"],
                likes: 8,
                comments: 1,
                isPublic: true,
                imageUrl: "https://picsum.photos/400/600?random=4",
                createdAt: Date().addingTimeInterval(-14400),
                updatedAt: Date().addingTimeInterval(-14400)
            ),
            ScentDiaryModel(
                id: "5",
                userId: "user5",
                userName: "향수 크리에이터",
                userProfileImage: "https://picsum.photos/100/100?random=50",
                perfumeId: "perfume5",
                perfumeName: "라 비 에 벨",
                brand: "랑콤",
                content: "@라 비 에 벨 을 뿌리고 카페에서 데이트했어요. 달콤한 바닐라 노트가 따뜻한 분위기를 만들어줬습니다. ☕️",
                tags: ["달콤한", "바닐라", "따뜻한"],
                likes: 12,
                comments: 4,
                isPublic: true,
                imageUrl: "https://picsum.photos/400/600?random=5",
                createdAt: Date().addingTimeInterval(-18000),
                updatedAt: Date().addingTimeInterval(-18000)
            )
        ]
        
        print("📄 [목업 데이터] 생성 완료: \(mockDiaries.count)개")
        print("📄 [목업 데이터] 공개 게시물: \(mockDiaries.filter { $0.isPublic }.count)개")
        print("📄 [목업 데이터] 비공개 게시물: \(mockDiaries.filter { !$0.isPublic }.count)개")
        for (index, diary) in mockDiaries.enumerated() {
            print("   \(index + 1). \(diary.userName): \(diary.perfumeName) - 공개: \(diary.isPublic)")
        }
        
        return mockDiaries
    }
    
    // MARK: - 미연동 diaries 엔드포인트 래퍼
    func uploadDiaryImage(diaryId: String, image: UIImage) async throws -> String {
        let response = try await apiClient.uploadDiaryImage(diaryId: diaryId, image: image)
        return response.image_url
    }
    func getDiaryStatsSummary() async throws -> DiaryStatsSummaryResponse {
        return try await apiClient.getDiaryStatsSummary()
    }
    func searchDiaries(query: String) async throws -> [ScentDiaryModel] {
        return try await apiClient.searchDiaries(query: query)
    }
    func getAllDiariesAdmin() async throws -> [ScentDiaryModel] {
        return try await apiClient.getAllDiariesAdmin()
    }
    func cleanupDiariesAdmin() async throws -> String {
        let response = try await apiClient.cleanupDiariesAdmin()
        return response.message
    }
    func getDiariesHealth() async throws -> DiaryHealthResponse {
        return try await apiClient.getDiariesHealth()
    }
    
    // MARK: - 신고 관리 엔드포인트 래퍼
    func reportDiary(diaryId: String, reason: String) async throws -> ReportResponse {
        return try await apiClient.reportDiary(diaryId: diaryId, reason: reason)
    }
    func getReports() async throws -> [ReportModel] {
        return try await apiClient.getReports()
    }
    func getReportStats() async throws -> ReportStatsResponse {
        return try await apiClient.getReportStats()
    }
    func handleReportAction(reportId: String, action: String) async throws -> ReportActionResponse {
        return try await apiClient.handleReportAction(reportId: reportId, action: action)
    }
    func deleteReport(reportId: String) async throws -> DeleteReportResponse {
        return try await apiClient.deleteReport(reportId: reportId)
    }
    
    // MARK: - 기존 메서드 (하위 호환성)
    
    /// 기존 createDiary 메서드 (하위 호환성)
    func createDiary(_ diary: ScentDiaryModel) async {
        let success = await createDiary(
            userId: diary.userId,
            perfumeName: diary.perfumeName,
            content: diary.content,
            isPublic: diary.isPublic,
            emotionTags: diary.emotionTags
        )
        
        if !success {
            // 실패 시 로컬에 추가 (폴백)
            diaries.insert(diary, at: 0)
        }
    }
    
    // MARK: - 로컬 데이터 관리
    
    /// 로컬 일기 데이터 저장
    private func saveLocalDiary(_ diary: ScentDiaryModel) async {
        print("💾 [로컬 저장] 시향 일기 저장 시작...")
        
        // 기존 로컬 일기 로드
        var localDiaries: [ScentDiaryModel] = []
        if let data = UserDefaults.standard.data(forKey: "localDiaries"),
           let savedDiaries = try? JSONDecoder().decode([ScentDiaryModel].self, from: data) {
            localDiaries = savedDiaries
        }
        
        // 중복 제거 (같은 ID가 있는지 확인)
        if !localDiaries.contains(where: { $0.id == diary.id }) {
            localDiaries.insert(diary, at: 0) // 최신 일기를 맨 앞에 추가
            print("💾 [로컬 저장] 새 일기 추가: \(diary.id)")
        } else {
            print("💾 [로컬 저장] 기존 일기 업데이트: \(diary.id)")
            // 기존 일기 업데이트
            if let index = localDiaries.firstIndex(where: { $0.id == diary.id }) {
                localDiaries[index] = diary
            }
        }
        
        // UserDefaults에 저장
        do {
            let data = try JSONEncoder().encode(localDiaries)
            UserDefaults.standard.set(data, forKey: "localDiaries")
            UserDefaults.standard.synchronize()
            print("✅ [로컬 저장] 시향 일기 저장 완료 (총 \(localDiaries.count)개)")
        } catch {
            print("❌ [로컬 저장] 시향 일기 저장 실패: \(error)")
        }
    }
    
    /// 로컬 일기 데이터 로드
    private func loadLocalDiaries() -> [ScentDiaryModel] {
        guard let data = UserDefaults.standard.data(forKey: "localDiaries"),
              let diaries = try? JSONDecoder().decode([ScentDiaryModel].self, from: data) else {
            print("📄 [로컬 로드] 저장된 로컬 일기 없음")
            return []
        }
        
        print("📄 [로컬 로드] 로컬 일기 \(diaries.count)개 로드")
        return diaries
    }
    
    /// 로컬 일기 데이터 초기화 (디버깅용)
    func clearLocalDiaries() {
        UserDefaults.standard.removeObject(forKey: "localDiaries")
        UserDefaults.standard.synchronize()
        print("🗑️ [로컬 데이터] 로컬 일기 데이터 초기화 완료")
    }
    
    /// 저장된 모든 로컬 데이터 확인 (디버깅용)
    func debugLocalData() {
        print("🔍 [디버깅] 저장된 로컬 데이터 확인:")
        
        // 로컬 시향 일기 확인
        if let data = UserDefaults.standard.data(forKey: "localDiaries"),
           let diaries = try? JSONDecoder().decode([ScentDiaryModel].self, from: data) {
            print("📄 [로컬 일기] \(diaries.count)개:")
            for (index, diary) in diaries.enumerated() {
                print("   \(index + 1). \(diary.userName) - \(diary.content.prefix(30))...")
                print("      태그: \(diary.tags)")
                print("      이미지: \(diary.imageUrl ?? "없음")")
                print("      공개: \(diary.isPublic)")
            }
        } else {
            print("📄 [로컬 일기] 없음")
        }
        
        // 프로필 일기 확인
        if let data = UserDefaults.standard.data(forKey: "diaryEntries"),
           let entries = try? JSONDecoder().decode([DiaryEntry].self, from: data) {
            print("📔 [프로필 일기] \(entries.count)개:")
            for (index, entry) in entries.enumerated() {
                print("   \(index + 1). \(entry.title) - \(entry.content.prefix(30))...")
            }
        } else {
            print("📔 [프로필 일기] 없음")
        }
        
        // 사용자 정보 확인
        let userId = UserDefaults.standard.string(forKey: "currentUserId") ?? "없음"
        let userName = UserDefaults.standard.string(forKey: "currentUserName") ?? "없음"
        let userProfile = UserDefaults.standard.string(forKey: "currentUserProfileImage") ?? "없음"
        print("👤 [사용자 정보] ID: \(userId), 이름: \(userName), 프로필: \(userProfile)")
    }
} 
