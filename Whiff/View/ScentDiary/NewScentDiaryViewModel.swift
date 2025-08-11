import Foundation
import SwiftUI
import Combine

class NewScentDiaryViewModel: ObservableObject {
    @Published var selectedPerfume: Perfume?
    @Published var selectedImage: UIImage?
    @Published var content: String = ""
    @Published var tagInput: String = ""
    @Published var tags: [String] = []
    @Published var isPublic: Bool = true
    @Published var error: Error?
    @Published var isLoading = false
    
    // 감정 태그 관련 상태
    @Published var suggestedTags: [EmotionTag] = []
    @Published var selectedTags: Set<String> = []
    
    private let apiClient = APIClient.shared
    
    func addTag() {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            tagInput = ""
        }
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    func saveDiary(viewModel: ScentDiaryViewModel) async throws {
        guard !content.isEmpty else {
            throw DiaryError.emptyContent
        }
        
        // 향수 이름이 직접 입력되지 않은 경우 처리
        let perfumeName = selectedPerfume?.name ?? "직접 입력한 향수"
        
        isLoading = true
        error = nil
        
        do {
            // 선택된 감정 태그들을 일반 태그로 변환
            let emotionTags = suggestedTags
                .filter { selectedTags.contains($0.id) }
                .map { $0.name }
            
            // 기존 태그와 감정 태그를 합침
            let allTags = Array(Set(tags + emotionTags))
            
            let userId = UserDefaults.standard.string(forKey: "currentUserId") ?? 
                        UserDefaults.standard.string(forKey: "userId") ?? ""
            
            // 디버깅 정보 출력
            print("🔍 [NewScentDiaryViewModel] 일기 저장 요청:")
            print("   - 사용자 ID: '\(userId)'")
            print("   - 향수명: '\(perfumeName)'")
            print("   - 내용: '\(content)'")
            print("   - 태그: \(allTags)")
            print("   - 공개 설정: \(isPublic)")
            print("   - 이미지 있음: \(selectedImage != nil)")
            
            // ScentDiaryViewModel의 새로운 createDiary 메서드 사용
            let success = await viewModel.createDiary(
                userId: userId,
                perfumeName: perfumeName,
                content: content,
                isPublic: isPublic,
                emotionTags: allTags,
                selectedImage: selectedImage
            )
            
            if !success {
                throw DiaryError.saveFailed
            }
            
        } catch {
            self.error = error
            throw error
        }
        
        isLoading = false
    }
}

enum DiaryError: LocalizedError {
    case emptyContent
    case noPerfumeSelected
    case invalidImage
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "일기 내용을 입력해주세요."
        case .noPerfumeSelected:
            return "향수를 선택해주세요."
        case .invalidImage:
            return "이미지 처리 중 오류가 발생했습니다."
        case .saveFailed:
            return "일기 저장에 실패했습니다."
        }
    }
} 