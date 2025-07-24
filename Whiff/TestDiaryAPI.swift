import Foundation

/// 시향 일기 API 테스트 클래스
class TestScentDiaryAPI {
    private let networkManager = NetworkManager.shared
    
    /// 시향 일기 작성 테스트
    func testCreateDiary() async {
        print("🧪 [시향 일기 API 테스트] 일기 작성 테스트 시작")
        
        let testRequest = ScentDiaryRequest(
            userId: "john_doe",
            perfumeName: "Chanel No.5",
            content: "오늘은 봄바람이 느껴지는 향수와 산책했어요. @Chanel No.5 와 함께한 특별한 하루였습니다.",
            isPublic: false,
            emotionTagsArray: ["차분", "봄"],
            imageUrl: "https://picsum.photos/400/600?random=123"
        )
        
        do {
            let createdDiary = try await networkManager.createScentDiary(testRequest)
            print("✅ [테스트 성공] 일기 작성 완료:")
            print("   - ID: \(createdDiary.id)")
            print("   - 향수: \(createdDiary.perfumeName)")
            print("   - 내용: \(createdDiary.content)")
            print("   - 태그: \(createdDiary.emotionTags.joined(separator: ", "))")
            print("   - 공개: \(createdDiary.isPublic ? "공개" : "비공개")")
            if let imageUrl = createdDiary.imageUrl {
                print("   - 이미지: \(imageUrl)")
            }
            
        } catch {
            print("❌ [테스트 실패] 일기 작성 실패: \(error)")
        }
    }
    
    /// 시향 일기 목록 조회 테스트
    func testFetchDiaries() async {
        print("🧪 [시향 일기 API 테스트] 일기 목록 조회 테스트 시작")
        
        do {
            let diaries = try await networkManager.fetchScentDiaries()
            print("✅ [테스트 성공] 일기 목록 조회 완료: \(diaries.count)개")
            
            for (index, diary) in diaries.enumerated() {
                print("   \(index + 1). \(diary.perfumeName) - \(diary.userId)")
                print("      내용: \(diary.content)")
                print("      태그: \(diary.emotionTags.joined(separator: ", "))")
                print("      작성일: \(diary.createdAt)")
                print("      공개: \(diary.isPublic ? "공개" : "비공개")")
                print("      ---")
            }
            
        } catch {
            print("❌ [테스트 실패] 일기 목록 조회 실패: \(error)")
        }
    }
    
    /// 특정 사용자 일기 조회 테스트
    func testFetchUserDiaries() async {
        print("🧪 [시향 일기 API 테스트] 사용자 일기 조회 테스트 시작")
        
        do {
            let diaries = try await networkManager.fetchScentDiaries(userId: "john_doe")
            print("✅ [테스트 성공] 사용자 일기 조회 완료: \(diaries.count)개")
            
            for (index, diary) in diaries.enumerated() {
                print("   \(index + 1). \(diary.perfumeName)")
                print("      내용: \(diary.content)")
                print("      공개: \(diary.isPublic ? "공개" : "비공개")")
                print("      브랜드: \(diary.brand ?? "Unknown")")
                print("      ---")
            }
            
        } catch {
            print("❌ [테스트 실패] 사용자 일기 조회 실패: \(error)")
        }
    }
    
    /// 감정 태그 추천 테스트
    func testEmotionTagSuggestion() async {
        print("🧪 [감정 태그 추천 테스트] 테스트 시작")
        
        let testContents = [
            "오늘은 봄바람이 느껴지는 향수와 산책했어요.",
            "상쾌한 시트러스 노트가 하루를 시작하는데 좋은 에너지를 줍니다.",
            "로맨틱한 데이트에 완벽한 향수였어요.",
            "차분하고 평온한 기분이 들어요."
        ]
        
        // @MainActor 컨텍스트에서 ScentDiaryViewModel 접근
        await MainActor.run {
            let viewModel = ScentDiaryViewModel()
            
            for (index, content) in testContents.enumerated() {
                let suggestedTags = viewModel.suggestEmotionTags(for: content)
                print("   \(index + 1). '\(content)'")
                print("      추천 태그: \(suggestedTags.joined(separator: ", "))")
                print("      ---")
            }
        }
        
        print("✅ [감정 태그 추천 테스트] 완료")
    }
    
    /// 전체 API 테스트 실행
    func runAllTests() async {
        print("🚀 [시향 일기 API 테스트] 전체 테스트 시작\n")
        
        // 1. 감정 태그 추천 테스트
        await testEmotionTagSuggestion()
        print("")
        
        // 2. 일기 작성 테스트
        await testCreateDiary()
        
        // 잠시 대기
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        print("")
        
        // 3. 전체 일기 목록 조회 테스트
        await testFetchDiaries()
        
        // 잠시 대기
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        print("")
        
        // 4. 사용자별 일기 조회 테스트
        await testFetchUserDiaries()
        
        print("\n🏁 [시향 일기 API 테스트] 모든 테스트 완료")
    }
} 