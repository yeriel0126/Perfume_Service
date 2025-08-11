//
//  ProjectStore.swift
//  Whiff
//
//  Created by 신희영 on 5/20/25.
//
import Foundation
import SwiftUI

@MainActor
class ProjectStore: ObservableObject {
    @Published var recommendations: [Perfume] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastPreferences: PerfumePreferences?
    @Published var modelStatus: String = "알 수 없음"
    @Published var modelVersion: String = "알 수 없음"
    @Published var isModelHealthy: Bool = true
    
    // 저장된 프로젝트들 (추천 향수 컬렉션)
    @Published var projects: [Project] = []
    
    private let apiClient = APIClient.shared
    private let projectsKey = "savedRecommendationProjects"
    
    init() {
        loadProjects()
    }
    
    // MARK: - 모델 상태 관리
    
    // 추천 모델 상태 확인
    func checkModelStatus() async {
        do {
            let status = try await apiClient.getSystemStatus()
            modelStatus = status.status
            modelVersion = status.model_version
            print("🔍 [모델 상태] \(status.status), 버전: \(status.model_version)")
        } catch {
            modelStatus = "오류"
            modelVersion = "알 수 없음"
            print("❌ [모델 상태 확인 실패] \(error)")
        }
    }
    
    // 추천 시스템 헬스 체크
    func checkSystemHealth() async {
        do {
            let health = try await apiClient.getHealth()
            isModelHealthy = health.status == "ok"
            print("🔍 [시스템 헬스] \(health.status)")
        } catch {
            isModelHealthy = false
            print("❌ [헬스 체크 실패] \(error)")
        }
    }
    
    // MARK: - 향수 추천 메서드
    
    // 향수 추천 받기 (1차 추천)
    func getRecommendations(preferences: PerfumePreferences) async {
        // 먼저 모델 상태 확인
        await checkModelStatus()
        await checkSystemHealth()
        
        if !isModelHealthy {
            error = NSError(domain: "RecommendationError", code: 503, userInfo: [
                NSLocalizedDescriptionKey: "추천 시스템이 일시적으로 사용할 수 없습니다. 잠시 후 다시 시도해주세요."
            ])
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let fetchedRecommendations = try await apiClient.recommendPerfumes(preferences: preferences)
            self.recommendations = fetchedRecommendations.map { $0.toPerfume() }
            self.lastPreferences = preferences
            
            print("✅ [일반 추천] \(fetchedRecommendations.count)개 추천 완료 (모델 버전: \(modelVersion))")
        } catch {
            self.error = error
            print("❌ [일반 추천 실패] \(error)")
        }
        
        isLoading = false
    }
    
    // 클러스터 기반 향수 추천 받기 (새로운 모델)
    func getClusterRecommendations(preferences: PerfumePreferences) async {
        // 먼저 모델 상태 확인
        await checkModelStatus()
        await checkSystemHealth()
        
        if !isModelHealthy {
            error = NSError(domain: "RecommendationError", code: 503, userInfo: [
                NSLocalizedDescriptionKey: "새로운 추천 모델이 일시적으로 사용할 수 없습니다. 일반 추천을 사용해주세요."
            ])
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let fetchedRecommendations = try await apiClient.recommendPerfumesByCluster(preferences: preferences)
            self.recommendations = fetchedRecommendations.map { $0.toPerfume() }
            self.lastPreferences = preferences
            
            print("✅ [클러스터 추천] \(fetchedRecommendations.count)개 추천 완료 (새로운 모델 버전: \(modelVersion))")
        } catch {
            self.error = error
            print("❌ [클러스터 추천 실패] \(error)")
            
            // 새로운 모델 실패시 기본 추천으로 대체
            print("🔄 [대체 추천] 기본 추천 모델로 시도...")
            await getRecommendations(preferences: preferences)
        }
        
        isLoading = false
    }
    
    // 1차 추천 받기 (감정 클러스터 기반)
    func getFirstRecommendation(preferences: PerfumePreferences) async throws -> FirstRecommendationResponse {
        await checkSystemHealth()
        
        if !isModelHealthy {
            throw NSError(domain: "RecommendationError", code: 503, userInfo: [
                NSLocalizedDescriptionKey: "추천 시스템이 일시적으로 사용할 수 없습니다."
            ])
        }
        
        isLoading = true
        error = nil
        
        do {
            let firstRecommendation = try await apiClient.getFirstRecommendation(preferences: preferences)
            isLoading = false
            print("✅ [1차 추천] 향수 개수: \(firstRecommendation.recommendations.count)개")
            return firstRecommendation
        } catch {
            self.error = error
            isLoading = false
            print("❌ [1차 추천 실패] \(error)")
            throw error
        }
    }
    
    // 2차 추천 받기 (사용자 노트 점수 기반)
    func getSecondRecommendations(userNoteScores: [String: Int], emotionProba: [Double], selectedIdx: [Int]) async throws -> [SecondRecommendationItem] {
        isLoading = true
        error = nil
        
        do {
            let requestBody = SecondRecommendationRequest(
                user_preferences: UserPreferencesForSecond(), // 기본값 사용
                user_note_scores: userNoteScores,
                emotion_proba: emotionProba,
                selected_idx: selectedIdx
            )
            
            let secondRecommendations = try await apiClient.getSecondRecommendation(requestData: requestBody)
            
            print("✅ 2차 추천 성공: \(secondRecommendations.recommendations.count)개 향수 추천")
            
            // SecondRecommendationItem을 Perfume으로 변환
            let convertedPerfumes = secondRecommendations.recommendations.map { $0.toPerfume() }
            recommendations = convertedPerfumes
            
            isLoading = false
            return secondRecommendations.recommendations
            
        } catch {
            print("❌ 2차 추천 실패: \(error)")
            self.error = error
            isLoading = false
            throw error
        }
    }
    
    // MARK: - 선호도 평가 제출
    
    // 선호도 평가 결과 제출
    func submitPreferenceRatings(projectId: UUID, ratings: [UUID: Int]) async throws {
        isLoading = true
        error = nil
        
        do {
            // 평가 결과를 서버에 저장하거나 처리하는 로직
            print("✅ [선호도 평가 제출] \(ratings.count)개 평가 저장됨")
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기 (서버 요청 시뮬레이션)
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            print("❌ [선호도 평가 제출 실패] \(error)")
            throw error
        }
    }
    
    // MARK: - 추천 결과 관리
    
    // 추천 결과 저장하기 (모델 학습용)
    func saveRecommendation(userId: String, perfumeIds: [String], preferences: [String: String]) async {
        isLoading = true
        error = nil
        
        do {
            let recommendationData = RecommendationSaveRequest(
                user_id: userId,
                perfume_ids: perfumeIds,
                preferences: preferences
            )
            _ = try await apiClient.saveRecommendation(recommendation: recommendationData)
            print("✅ [추천 저장] 사용자 피드백이 모델 학습에 반영됩니다")
        } catch {
            self.error = error
            print("❌ [추천 저장 실패] \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - 향수 데이터 관리
    
    // 모든 향수 목록 가져오기
    func fetchAllPerfumes() async {
        isLoading = true
        error = nil
        
        do {
            let perfumeResponses = try await apiClient.getPerfumes()
            let perfumes = perfumeResponses.map { $0.toPerfume() }
            self.recommendations = perfumes
            print("✅ [향수 목록] \(perfumes.count)개 향수 로드 완료")
        } catch {
            self.error = error
            print("❌ [향수 목록 로드 실패] \(error)")
        }
        
        isLoading = false
    }
    
    // 향수 상세 정보 가져오기
    func getPerfumeDetail(name: String) async throws -> PerfumeDetailResponse {
        isLoading = true
        error = nil
        
        do {
            let detail = try await apiClient.getPerfumeDetail(name: name)
            isLoading = false
            print("✅ [향수 상세] \(name) 정보 로드 완료")
            return detail
        } catch {
            self.error = error
            isLoading = false
            print("❌ [향수 상세 로드 실패] \(error)")
            throw error
        }
    }
    
    // MARK: - 유틸리티 메서드
    
    // 추천 결과 초기화
    func clearRecommendations() {
        Task {
            do {
                _ = try await apiClient.clearMyRecommendations()
                print("✅ [백엔드 전체 삭제] 모든 추천 기록이 서버에서 삭제되었습니다")
            } catch {
                print("❌ [백엔드 전체 삭제 실패] \(error)")
            }
            projects.removeAll()
            recommendations.removeAll()
            saveProjects()
            print("🧹 [전체 삭제] 모든 추천 기록이 삭제되었습니다")
        }
    }
    
    // 새로운 모델 사용 가능 여부 확인
    func isNewModelAvailable() -> Bool {
        return isModelHealthy && modelStatus == "ready"
    }
    
    // 모델 성능 로깅
    func logRecommendationPerformance(startTime: Date, recommendationCount: Int) {
        let duration = Date().timeIntervalSince(startTime)
        print("📊 [성능 로그] 추천 완료: \(recommendationCount)개, 소요시간: \(String(format: "%.2f", duration))초, 모델 버전: \(modelVersion)")
    }
    
    // 오늘의 향수 추천 (임시)
    func generateDailyRecommendations() async {
        isLoading = true
        
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기 (서버 요청 시뮬레이션)
            
            // 오늘의 향수 추천 로직을 구현해야 합니다.
            
        } catch {
            print("❌ 오늘의 향수 추천 실패: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - 프로젝트 관리
    
    // 새로운 추천 프로젝트 추가
    func addProject(_ project: Project) {
        projects.append(project)
        saveProjects()
        print("💾 [프로젝트 저장] '\(project.name)' 프로젝트가 My Collection에 추가되었습니다")
    }
    
    // 프로젝트 삭제
    func removeProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        saveProjects()
        print("🗑️ [프로젝트 삭제] '\(project.name)' 프로젝트가 삭제되었습니다")
    }
    
    // 프로젝트 업데이트
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveProjects()
            print("✏️ [프로젝트 업데이트] '\(project.name)' 프로젝트가 업데이트되었습니다")
        }
    }
    
    // 특정 프로젝트 조회
    func getProject(by id: UUID) -> Project? {
        return projects.first { $0.id == id.uuidString }
    }
    
    // MARK: - 데이터 저장/로드
    
    private func saveProjects() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(projects)
            UserDefaults.standard.set(data, forKey: projectsKey)
            print("💾 [저장 완료] \(projects.count)개 프로젝트 저장됨")
        } catch {
            print("❌ [저장 실패] \(error)")
        }
    }
    
    private func loadProjects() {
        guard let data = UserDefaults.standard.data(forKey: projectsKey) else {
            print("📂 [로드] 저장된 프로젝트가 없습니다")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            projects = try decoder.decode([Project].self, from: data)
            print("📂 [로드 완료] \(projects.count)개 프로젝트 로드됨")
        } catch {
            print("❌ [로드 실패] \(error)")
            projects = []
        }
    }
}


