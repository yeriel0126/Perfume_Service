import SwiftUI

// MARK: - DateFormatter 확장
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM월 dd일"
        return formatter
    }()
}

// MARK: - 화면 상태
enum RecommendationScreenState {
    case firstRecommendations    // 1차 추천 결과
    case noteEvaluation         // 향 노트 평가
    case finalRecommendations   // 최종 추천 결과
}

struct FinalRecommendationView: View {
    let projectName: String
    let firstRecommendationData: FirstRecommendationResponse?
    let userPreferences: PerfumePreferences?
    
    @State private var userNoteRatings: [String: Int] = [:]
    @State private var finalRecommendations: [Perfume] = []
    @State private var emotionSummary: String = ""
    @State private var isSaved = false
    @State private var isLoading = false
    @State private var error: Error?
    @State private var currentScreen: RecommendationScreenState = .firstRecommendations
    @State private var recommendationDiagnosis: RecommendationDiagnosis?

    @EnvironmentObject var projectStore: ProjectStore
    private let networkManager = NetworkManager.shared

    // 생성자 수정
    init(projectName: String, firstRecommendationData: FirstRecommendationResponse?, userPreferences: PerfumePreferences?) {
        self.projectName = projectName
        self.firstRecommendationData = firstRecommendationData
        self.userPreferences = userPreferences
    }

    var body: some View {
        // NavigationView 제거하고 직접 레이아웃 관리
        switch currentScreen {
        case .firstRecommendations:
            FirstRecommendationScreen(
                projectName: projectName,
                firstRecommendationData: firstRecommendationData,
                onContinue: {
                    currentScreen = .noteEvaluation
                }
            )
            
        case .noteEvaluation:
            NoteEvaluationScreen(
                userNoteRatings: $userNoteRatings,
                firstRecommendationData: firstRecommendationData,
                onBack: {
                    currentScreen = .firstRecommendations
                },
                onContinue: {
                    currentScreen = .finalRecommendations
                    Task {
                        await loadFinalResults()
                    }
                }
            )
            
        case .finalRecommendations:
            if !finalRecommendations.isEmpty {
                // 최종 향수 추천 목록 화면 - 네비게이션 중복 제거
                VStack(spacing: 0) {
                    // 추천 품질 진단 (문제가 있을 때만 표시)
                    if let diagnosis = recommendationDiagnosis, diagnosis.isProblematic {
                        RecommendationDiagnosisCard(diagnosis: diagnosis)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                    }
                    
                    // 향수 목록 - 전체 공간 사용
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(finalRecommendations.enumerated()), id: \.element.id) { index, perfume in
                                PerfumeRecommendationCard(
                                    perfume: perfume,
                                    rank: index + 1,
                                    showDetailedInfo: true
                                )
                            }
                            
                            // 저장 버튼을 스크롤 내용 하단에 포함
                            VStack(spacing: 12) {
                                if !isSaved {
                                    Button(action: {
                                        Task {
                                            await saveRecommendations()
                                        }
                                    }) {
                                        Text("My Collection에 저장")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(Color.accentColor)
                                            .cornerRadius(12)
                                    }
                                } else {
                                    Text("✅ My Collection에 저장되었습니다")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 30)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
                .navigationTitle("맞춤 향수")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text("\(finalRecommendations.count)개 추천")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // 최종 추천 로딩/오류 화면
                FinalAnalysisScreen(
                    projectName: projectName,
                    userNoteRatings: userNoteRatings,
                    isLoading: isLoading,
                    error: error,
                    onBack: {
                        currentScreen = .noteEvaluation
                    },
                    onRetry: {
                        Task {
                            await loadFinalResults()
                        }
                    }
                )
            }
        }
    }

    private func loadFinalResults() async {
        isLoading = true
        error = nil
        
        do {
            // 실제 사용자 노트 평가 데이터 확인
            guard !userNoteRatings.isEmpty else {
                throw NSError(domain: "사용자 노트 평가가 없습니다", code: -1, userInfo: nil)
            }
            
            // 감정 확률 (1차 추천에서 얻은 실제 데이터)
            let emotionProba = firstRecommendationData?.clusterInfo?.proba ?? [0.16, 0.16, 0.17, 0.17, 0.17, 0.17]
            
            // 선택된 인덱스 (1차 추천 결과)
            let selectedIdx = firstRecommendationData?.clusterInfo?.selected_idx ?? []
            
            print("📤 [최종 추천 요청 데이터]")
            print("   - 실제 사용자 노트 평가: \(userNoteRatings)")
            print("   - 감정 확률 (1차 추천 결과): \(emotionProba)")
            print("   - 선택된 인덱스 (1차 추천 결과): \(selectedIdx)")
            print("   - 사용자 선호도: \(userPreferences?.description ?? "nil")")
            
            // 🔥 사용자 입력 변화 추적을 위한 상세 로그
            print("🎯 [사용자 노트 평가 분석]")
            print("   📊 노트 평가 통계:")
            for (note, rating) in userNoteRatings.sorted(by: { $0.key < $1.key }) {
                let preference = rating >= 4 ? "좋아함" : (rating <= 1 ? "싫어함" : "보통")
                print("      \(note): \(rating)점 (\(preference))")
            }
            
            let ratingCounts = Dictionary(grouping: userNoteRatings.values, by: { $0 }).mapValues { $0.count }
            print("   📊 평점 분포: \(ratingCounts.sorted(by: { $0.key < $1.key }))")
            print("   📊 평균 평점: \(String(format: "%.2f", Double(userNoteRatings.values.reduce(0, +)) / Double(userNoteRatings.count)))")
            print("   📊 좋아하는 노트: \(userNoteRatings.filter { $0.value >= 4 }.keys.sorted())")
            print("   📊 싫어하는 노트: \(userNoteRatings.filter { $0.value <= 1 }.keys.sorted())")
            
            // 백엔드 API 스펙 검증
            let isValidEmotionProba = emotionProba.count == 6 && emotionProba.allSatisfy { $0 >= 0 && $0 <= 1 }
            let isValidNoteScores = !userNoteRatings.isEmpty && userNoteRatings.allSatisfy { $0.value >= 0 && $0.value <= 5 }
            let isValidSelectedIdx = !selectedIdx.isEmpty && selectedIdx.allSatisfy { $0 >= 0 }
            
            print("🔍 [API 스펙 검증]")
            print("   - emotion_proba (6개, 0-1): \(isValidEmotionProba ? "✅" : "❌")")
            print("   - user_note_scores (0-5): \(isValidNoteScores ? "✅" : "❌")")
            print("   - selected_idx (0+): \(isValidSelectedIdx ? "✅" : "❌")")
            
            // 🚨 백엔드팀 확인 사항 상세 출력
            if !isValidEmotionProba {
                print("❌ [백엔드 확인 필요] emotion_proba 문제:")
                print("   현재 값: \(emotionProba)")
                print("   예상: 6개 요소, 각각 0.0-1.0 범위")
                print("   실제: \(emotionProba.count)개 요소")
                if emotionProba.count == 6 {
                    print("   범위 벗어난 값들: \(emotionProba.enumerated().filter { !($0.element >= 0 && $0.element <= 1) })")
                }
            }
            
            if !isValidSelectedIdx {
                print("❌ [백엔드 확인 필요] selected_idx 문제:")
                print("   현재 값: \(selectedIdx)")
                print("   예상: 1개 이상의 양수 인덱스")
                print("   실제: \(selectedIdx.count)개 요소")
                if !selectedIdx.isEmpty {
                    print("   음수 인덱스들: \(selectedIdx.filter { $0 < 0 })")
                }
            }
            
            // 기본값 사용 여부 확인
            let isUsingDefaultProba = emotionProba == [0.16, 0.16, 0.17, 0.17, 0.17, 0.17]
            let isUsingEmptyIdx = selectedIdx.isEmpty
            
            if isUsingDefaultProba || isUsingEmptyIdx {
                print("⚠️ [백엔드 확인 시급] 1차 추천 API 응답 문제:")
                if isUsingDefaultProba {
                    print("   - emotion_proba가 기본값으로 설정됨 (백엔드에서 null/undefined 전송)")
                }
                if isUsingEmptyIdx {
                    print("   - selected_idx가 빈 배열 (백엔드에서 null/undefined 전송)")
                }
                print("   💡 백엔드팀 확인사항:")
                print("      1. /perfumes/recommend-cluster API가 'proba' 필드를 포함하는지 확인")
                print("      2. /perfumes/recommend-cluster API가 'selected_idx' 필드를 포함하는지 확인")
                print("      3. 응답 JSON 구조가 ClusterRecommendResponse와 일치하는지 확인")
            }
            
            guard isValidEmotionProba && isValidNoteScores && isValidSelectedIdx else {
                throw NSError(domain: "백엔드 API 스펙에 맞지 않는 데이터", code: -2, userInfo: nil)
            }
            
            // 2차 추천 API 호출 - 실제 사용자 노트 평가 데이터 사용
            print("🚀 [2차 추천 API 호출] 실제 사용자 노트 평가 데이터 사용")
            
            let secondRecommendations = try await networkManager.getSecondRecommendations(
                userPreferences: userPreferences,
                userNoteScores: userNoteRatings,
                emotionProba: emotionProba,
                selectedIdx: selectedIdx
            )
            
            // SecondRecommendationItem을 Perfume으로 변환
            let perfumes = secondRecommendations.map { $0.toPerfume() }
            
            finalRecommendations = perfumes
            
            print("✅ [2차 추천 성공] \(perfumes.count)개 최종 향수 추천")
            
            // 추천 결과 분석 및 진단
            let firstRecommendationPerfumes = extractPerfumeNamesFromFirstRecommendation()
            let secondRecommendationPerfumes = perfumes.map { $0.name }
            
            // 중복 분석
            let overlap = Set(firstRecommendationPerfumes).intersection(Set(secondRecommendationPerfumes))
            let overlapPercentage = firstRecommendationPerfumes.isEmpty ? 0 : (Double(overlap.count) / Double(firstRecommendationPerfumes.count)) * 100
            
            print("🔍 [추천 시스템 성능 분석]")
            print("   📊 1차 추천 향수: \(firstRecommendationPerfumes)")
            print("   📊 2차 추천 향수: \(secondRecommendationPerfumes)")
            print("   📊 중복 향수: \(overlap.sorted())")
            print("   📊 중복률: \(String(format: "%.1f", overlapPercentage))%")
            
            // 추천 진단 결과 생성
            let overlapCount = overlap.count
            let totalFirstRecommendations = firstRecommendationPerfumes.count
            let totalSecondRecommendations = secondRecommendationPerfumes.count
            
            var recommendationQuality: RecommendationDiagnosis.RecommendationQuality
            var isProblematic = false
            var diagnosisMessage = "추천 시스템이 정상적으로 작동하고 있습니다."
            
            // 중복도에 따른 품질 판정
            if overlapPercentage >= 90 {
                recommendationQuality = .critical
                isProblematic = true
                diagnosisMessage = "심각: 1차와 2차 추천이 \(String(format: "%.1f", overlapPercentage))% 동일합니다. 사용자 노트 평가가 전혀 반영되지 않았습니다."
            } else if overlapPercentage >= 70 {
                recommendationQuality = .poor
                isProblematic = true
                diagnosisMessage = "문제: 1차와 2차 추천이 \(String(format: "%.1f", overlapPercentage))% 유사합니다. 노트 평가 반영도가 낮습니다."
            } else if overlapPercentage >= 50 {
                recommendationQuality = .fair
                isProblematic = true
                diagnosisMessage = "주의: 1차와 2차 추천이 \(String(format: "%.1f", overlapPercentage))% 유사합니다. 더 다양한 노트 평가가 필요합니다."
            } else if overlapPercentage >= 30 {
                recommendationQuality = .good
                diagnosisMessage = "양호: 적절한 수준의 다양성이 확보되었습니다. (\(String(format: "%.1f", overlapPercentage))% 중복)"
            } else {
                recommendationQuality = .excellent
                diagnosisMessage = "우수: 사용자 노트 평가가 잘 반영되어 다양한 향수가 추천되었습니다. (\(String(format: "%.1f", overlapPercentage))% 중복)"
            }
            
            // 완전히 동일한 순서인지 체크
            let isIdenticalOrder = firstRecommendationPerfumes == secondRecommendationPerfumes
            if isIdenticalOrder && !firstRecommendationPerfumes.isEmpty {
                recommendationQuality = .critical
                isProblematic = true
                diagnosisMessage = "치명적: 향수 이름과 순서가 100% 동일합니다. 2차 추천 API가 작동하지 않고 있습니다."
            }
            
            recommendationDiagnosis = RecommendationDiagnosis(
                overlapPercentage: overlapPercentage,
                overlapCount: overlapCount,
                totalFirstRecommendations: totalFirstRecommendations,
                totalSecondRecommendations: totalSecondRecommendations,
                isProblematic: isProblematic,
                diagnosisMessage: diagnosisMessage,
                recommendationQuality: recommendationQuality
            )
            
            // 감정 분석 결과 생성 (진단 결과에 따라)
            if isProblematic {
                emotionSummary = """
                ⚠️ AI 추천 시스템 알림
                
                \(diagnosisMessage)
                
                이는 노트 평가가 최종 추천에 제대로 반영되지 않고 있음을 의미합니다.
                
                📊 진단 상세:
                • 1차 추천: \(totalFirstRecommendations)개
                • 2차 추천: \(totalSecondRecommendations)개  
                • 중복 향수: \(overlapCount)개 (\(String(format: "%.1f", overlapPercentage))%)
                
                💡 개선 방법:
                • 향 노트 평가를 더 극단적으로 해보세요 (0점 또는 5점)
                • 좋아하는 노트와 싫어하는 노트를 명확히 구분해주세요
                • 백엔드 팀에 AI 모델 상태 점검을 요청하세요
                
                현재 추천 결과는 참고용으로만 활용해주시기 바랍니다.
                """
            } else {
                // 정상적인 경우 - 사용자 노트 평가 기반 요약
                emotionSummary = generateEmotionSummaryFromNotes(userNoteRatings)
            }
            
            print("🎯 [최종 추천 완료] \(finalRecommendations.count)개 향수")
            print("📊 [추천 품질] \(recommendationQuality) - \(diagnosisMessage)")
            
        } catch {
            self.error = error
            print("❌ [2차 추천 실패] \(error)")
        }
        
        isLoading = false
    }
    
    // 사용자 노트 평가 기반 감정 요약 생성
    private func generateEmotionSummaryFromNotes(_ noteRatings: [String: Int]) -> String {
        let likedNotes = noteRatings.filter { $0.value >= 4 }.keys.sorted()
        let dislikedNotes = noteRatings.filter { $0.value <= 1 }.keys.sorted()
        
        var summary = "당신의 향 선호도 분석 결과:\n\n"
        
        if !likedNotes.isEmpty {
            summary += "✨ 좋아하는 향: \(likedNotes.joined(separator: ", "))\n"
        }
        
        if !dislikedNotes.isEmpty {
            summary += "❌ 피하고 싶은 향: \(dislikedNotes.joined(separator: ", "))\n"
        }
        
        summary += "\n이러한 선호도를 바탕으로 맞춤 향수를 추천해드렸습니다."
        
        return summary
    }
    
    // 1차 추천에서 향수 이름 추출 (진단용)
    private func extractPerfumeNamesFromFirstRecommendation() -> [String] {
        guard let clusterInfo = firstRecommendationData?.clusterInfo else {
            return []
        }
        
        // 실제로는 perfume index를 perfume name으로 변환해야 하지만,
        // 여기서는 진단 목적으로 인덱스를 문자열로 변환
        return clusterInfo.selected_idx.map { "Perfume_\($0)" }
    }
    
    // My Collection에 추천 향수들 저장
    private func saveRecommendations() async {
        guard !finalRecommendations.isEmpty else { return }
        
        print("💾 [My Collection 저장] \(finalRecommendations.count)개 향수 저장 시작")
        
        // 감정 분석 요약 생성
        let emotionAnalysisSummary = generateEmotionAnalysisSummary()
        
        let project = Project(
            id: UUID(),
            name: projectName,
            recommendations: finalRecommendations,
            emotionSummary: emotionAnalysisSummary,
            createdDate: Date(),
            userPreferences: userPreferences,
            userNoteRatings: userNoteRatings
        )
        
        projectStore.addProject(project)
        
        await MainActor.run {
            isSaved = true
        }
        
        print("✅ [My Collection 저장 완료] 프로젝트 '\(projectName)' 저장됨")
    }

    // 감정 분석 요약 생성
    private func generateEmotionAnalysisSummary() -> String {
        var summary: [String] = []
        
        // 1차 추천에서 얻은 감정 클러스터 정보
        if let clusterInfo = firstRecommendationData?.clusterInfo {
            summary.append("🧠 감정 클러스터 \(clusterInfo.cluster): \(clusterInfo.description)")
            summary.append("📊 확률: \(String(format: "%.1f", clusterInfo.proba[clusterInfo.cluster] * 100))%")
        }
        
        // 사용자 노트 평가 분석
        if !userNoteRatings.isEmpty {
            let likedNotes = userNoteRatings.filter { $0.value >= 4 }
            let dislikedNotes = userNoteRatings.filter { $0.value <= 1 }
            
            if !likedNotes.isEmpty {
                summary.append("💚 선호하는 향: \(likedNotes.keys.sorted().joined(separator: ", "))")
            }
            
            if !dislikedNotes.isEmpty {
                summary.append("❌ 피하는 향: \(dislikedNotes.keys.sorted().joined(separator: ", "))")
            }
            
            let averageRating = Double(userNoteRatings.values.reduce(0, +)) / Double(userNoteRatings.count)
            summary.append("📊 평균 향 평가: \(String(format: "%.1f", averageRating))점")
        }
        
        // 사용자 선호도 정보
        if let preferences = userPreferences {
            summary.append("👤 사용자 선호도:")
            summary.append("  - 성별: \(preferences.gender)")
            summary.append("  - 계절: \(preferences.seasonTags)")
            summary.append("  - 시간대: \(preferences.timeTags)")
            summary.append("  - 원하는 인상: \(preferences.desiredImpression)")
            summary.append("  - 활동: \(preferences.activity)")
            summary.append("  - 날씨: \(preferences.weather)")
        }
        
        summary.append("🎯 총 \(finalRecommendations.count)개 향수 추천")
        summary.append("📅 생성일: \(DateFormatter.shortDate.string(from: Date()))")
        
        return summary.joined(separator: "\n")
    }
}

// MARK: - 1차 추천 결과 화면
struct FirstRecommendationScreen: View {
    let projectName: String
    let firstRecommendationData: FirstRecommendationResponse?
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            VStack(spacing: 12) {
                Text("1차 추천 완료!")
                    .font(.title)
                    .bold()
                
                Text("감정 분석 결과를 확인해보세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            ScrollView {
                VStack(spacing: 16) {
                    // 감정 클러스터 정보
                    if let clusterInfo = firstRecommendationData?.clusterInfo {
                        VStack(spacing: 6) {
                            Text("🧠 감정 분석 결과")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.purple)
                            
                            Text("\(clusterInfo.description)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("클러스터 \(clusterInfo.cluster)")
                                .font(.caption2)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // 1차 추천 향수들 (있는 경우)
                    if let recommendations = firstRecommendationData?.recommendations, !recommendations.isEmpty {
                        VStack(spacing: 10) {
                            Text("🎯 AI 추천 향수 (\(recommendations.count)개)")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Text("감정 분석을 통해 선별된 향수들입니다\n다음 단계에서 더 정확한 맞춤 추천을 받아보세요")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            VStack(spacing: 10) {
                                ForEach(Array(recommendations.enumerated()), id: \.element.perfume_index) { index, recommendation in
                                    FirstRecommendationPerfumeCard(recommendation: recommendation, rank: index + 1)
                                }
                            }
                        }
                    }
                    
                    // 다음 단계 안내
                    VStack(spacing: 10) {
                        Text("🌿 다음 단계")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("향 노트를 평가하여\n더 정확한 맞춤 추천을 받아보세요!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            // 계속하기 버튼
            Button("향 노트 평가하기") {
                onContinue()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.accentColor)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - 1차 추천 향수 카드
struct FirstRecommendationPerfumeCard: View {
    let recommendation: FirstRecommendationItem
    let rank: Int
    
    @State private var perfume: Perfume?
    @State private var isLoading = true
    private let networkManager = NetworkManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 상단: 순위, 이름, 브랜드
            HStack(spacing: 12) {
                // 순위 배지
                ZStack {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 40, height: 40)
                    
                    Text("\(rank)")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                }
                
                // 향수 정보
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(perfume?.brand ?? "브랜드 정보 로딩 중...")")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text("\(perfume?.name ?? "향수 이름 로딩 중...")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 매치 점수
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.caption)
                        
                        Text("매치도 \(String(format: "%.1f", perfume?.similarity ?? 0 * 100))%")
                            .font(.caption)
                            .foregroundColor(.pink)
                    }
                }
                
                Spacer()
                
                // 향수 이미지
                AsyncImage(url: URL(string: perfume?.imageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .font(.title2)
                                    Text("이미지 로드 실패")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            )
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .tint(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            )
                    }
                }
                .frame(width: 60, height: 80)
                .cornerRadius(8)
                .clipped()
            }
            
            // 감정 태그 표시
            if !(perfume?.emotionTags.isEmpty ?? true) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🎯 감정 특성")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.purple)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(perfume?.emotionTags.prefix(4) ?? [], id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // 향수 설명 (상세 정보 포함)
            if !(perfume?.description.isEmpty ?? true) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💭 AI 추천 분석")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.green)
                    
                    Text(perfume?.description ?? "향수 설명 로딩 중...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(6)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
                .background(Color.green.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .task {
            await loadPerfumeInfo()
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color.brown
        default: return .purple
        }
    }
    
    private func loadPerfumeInfo() async {
        do {
            let fetchedPerfume = try await networkManager.fetchPerfumeByIndex(recommendation.perfume_index)
            await MainActor.run {
                self.perfume = fetchedPerfume
                self.isLoading = false
            }
            print("✅ [1차 추천 향수 정보] 인덱스 \(recommendation.perfume_index): \(fetchedPerfume.brand) - \(fetchedPerfume.name)")
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("❌ [1차 추천 향수 정보 실패] 인덱스 \(recommendation.perfume_index): \(error)")
        }
    }
}

// MARK: - 향 노트 평가 화면
struct NoteEvaluationScreen: View {
    @Binding var userNoteRatings: [String: Int]
    let firstRecommendationData: FirstRecommendationResponse?
    let onBack: () -> Void
    let onContinue: () -> Void
    
    @State private var showNoteGuide = false
    
    // 1차 추천에서 나온 주요 노트들 또는 기본 노트들
    private var notes: [String] {
        if let recommendedNotes = firstRecommendationData?.clusterInfo?.recommended_notes, 
           !recommendedNotes.isEmpty {
            // 1차 추천에서 나온 노트들 사용 (최대 10개)
            return Array(recommendedNotes.prefix(10))
        } else {
            // 폴백: 주요 8개 노트
            return [
                "시트러스", "베르가못", "장미", "자스민", 
                "샌달우드", "머스크", "바닐라", "앰버"
            ]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("뒤로")
                    }
                    .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("향 노트 평가")
                        .font(.headline)
                        .bold()
                    
                    Text("선호도를 알려주세요")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 향조 가이드 버튼
                Button(action: { showNoteGuide = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                        Text("노트 가이드")
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(15)
                }
            }
            .padding(.horizontal)
            .padding(.top, 0)
            .padding(.bottom, 0)
            
            // 진행률
            VStack(spacing: 4) {
                HStack {
                    Text("평가 완료")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(userNoteRatings.count)/\(notes.count)")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .bold()
                }
                
                ProgressView(value: Double(userNoteRatings.count), total: Double(notes.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // 향 노트 목록
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(notes, id: \.self) { note in
                        NoteRatingRow(
                            note: note,
                            rating: userNoteRatings[note] ?? 2,
                            onRatingChanged: { newRating in
                                userNoteRatings[note] = newRating
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // 하단 버튼
            VStack(spacing: 12) {
                let completedCount = userNoteRatings.count
                let totalCount = notes.count
                let completionPercentage = Double(completedCount) / Double(totalCount)
                
                if completionPercentage >= 0.6 { // 60% 이상 완료
                    Button("맞춤 추천 받기") {
                        onContinue()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(12)
                } else {
                    VStack(spacing: 8) {
                        Text("더 정확한 추천을 위해")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("최소 \(Int(Double(totalCount) * 0.6))개 이상 평가해주세요")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button("맞춤 추천 받기") {
                            onContinue()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray)
                        .cornerRadius(12)
                        .disabled(true)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showNoteGuide) {
            NoteGuideSheet(showNoteGuide: $showNoteGuide)
        }
    }
}

// MARK: - 노트 가이드 시트
private struct NoteGuideSheet: View {
    @Binding var showNoteGuide: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    NoteGuideScentCategoryView()
                    NoteGuideScentNoteView()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("향조 가이드")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        showNoteGuide = false
                    }
                }
            }
        }
    }
}

// MARK: - 향조 계열 가이드
private struct NoteGuideScentCategoryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("향조 계열")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            Group {
                NoteGuideScentCategoryItem(
                    title: "🌸 플로럴 (Floral)",
                    description: "부드럽고 여성스러운 꽃 향기. 봄에 어울리는 화사한 느낌.",
                    examples: "rose, jasmine, peony, lily, freesia, violet, magnolia, cherry blossom",
                    color: .pink
                )
                
                NoteGuideScentCategoryItem(
                    title: "🌳 우디 (Woody)", 
                    description: "따뜻하고 고요한 나무 향. 고급스럽고 안정적인 인상을 줍니다.",
                    examples: "sandalwood, cedar, vetiver, patchouli, oak, pine, guaiac wood, cypress",
                    color: .brown
                )
                
                NoteGuideScentCategoryItem(
                    title: "🍋 시트러스 (Citrus)",
                    description: "상쾌하고 활기찬 감귤류 향. 깔끔하고 에너지 넘치는 느낌.",
                    examples: "bergamot, lemon, orange, grapefruit, lime, yuzu, mandarin",
                    color: .orange
                )
                
                NoteGuideScentCategoryItem(
                    title: "🌿 아로마틱 (Aromatic)",
                    description: "허브와 향신료의 신선하고 자극적인 향. 자연스럽고 깨끗한 느낌.",
                    examples: "lavender, rosemary, mint, thyme, sage, basil, eucalyptus",
                    color: .green
                )
                
                NoteGuideScentCategoryItem(
                    title: "🍯 오리엔탈 (Oriental)",
                    description: "달콤하고 이국적인 향. 관능적이고 신비로운 분위기를 연출.",
                    examples: "vanilla, amber, musk, oud, frankincense, myrrh, benzoin",
                    color: .purple
                )
                
                NoteGuideScentCategoryItem(
                    title: "🌊 프레시 (Fresh)",
                    description: "깨끗하고 시원한 바다와 물의 향. 청량감과 순수함을 표현.",
                    examples: "marine, water lily, cucumber, green tea, bamboo, ozone",
                    color: .blue
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 향조 계열 아이템
private struct NoteGuideScentCategoryItem: View {
    let title: String
    let description: String
    let examples: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(color)
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
            Text("예시: \(examples)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 주요 향조 설명
private struct NoteGuideScentNoteView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("주요 향조 설명")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(scentNotes, id: \.name) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• \(note.name)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text(note.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 12)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private let scentNotes = [
        NoteGuideScentNote(name: "Bergamot (베르가못)", description: "상큼하고 시트러스한 향으로 향수에 생기를 부여하며 톱노트에서 많이 사용됩니다."),
        NoteGuideScentNote(name: "Rose (장미)", description: "클래식하고 우아한 꽃향기로 여성스럽고 로맨틱한 느낌을 줍니다."),
        NoteGuideScentNote(name: "Jasmine (자스민)", description: "달콤하고 관능적인 꽃향기로 밤에 더욱 강하게 향을 발합니다."),
        NoteGuideScentNote(name: "Sandalwood (샌달우드)", description: "크리미하고 따뜻한 나무향으로 베이스노트에서 깊이와 지속성을 제공합니다."),
        NoteGuideScentNote(name: "Vanilla (바닐라)", description: "달콤하고 부드러운 향으로 편안함과 따뜻함을 주는 인기 노트입니다."),
        NoteGuideScentNote(name: "Patchouli (패출리)", description: "흙냄새가 나는 독특한 향으로 보헤미안적이고 신비로운 분위기를 연출합니다."),
        NoteGuideScentNote(name: "Musk (머스크)", description: "동물성 향으로 관능적이고 따뜻한 느낌을 주며 베이스노트로 많이 사용됩니다."),
        NoteGuideScentNote(name: "Cedar (시더)", description: "건조하고 우디한 느낌으로 남성적이고 강인한 인상을 줍니다."),
        NoteGuideScentNote(name: "Lavender (라벤더)", description: "진정 효과가 있는 허브향으로 편안하고 깨끗한 느낌을 줍니다."),
        NoteGuideScentNote(name: "Amber (앰버)", description: "따뜻하고 달콤한 수지향으로 깊이와 복합성을 더해줍니다."),
        NoteGuideScentNote(name: "Oud (우드)", description: "중동의 귀한 나무향으로 매우 강하고 독특한 향을 가집니다."),
        NoteGuideScentNote(name: "Iris (아이리스)", description: "파우더리하고 우아한 꽃향기로 세련되고 고급스러운 느낌을 줍니다."),
        NoteGuideScentNote(name: "Vetiver (베티버)", description: "뿌리에서 나는 흙내음과 풀냄새로 자연스럽고 신선한 느낌을 줍니다."),
        NoteGuideScentNote(name: "Tonka Bean (통카빈)", description: "바닐라와 아몬드가 섞인 듯한 달콤한 향으로 따뜻함을 더해줍니다."),
        NoteGuideScentNote(name: "Black Pepper (블랙페퍼)", description: "스파이시하고 따뜻한 향신료 향으로 활력과 에너지를 줍니다.")
    ]
}

// MARK: - 향조 노트 모델
private struct NoteGuideScentNote {
    let name: String
    let description: String
}

// MARK: - 향 노트 평가 행
struct NoteRatingRow: View {
    let note: String
    let rating: Int
    let onRatingChanged: (Int) -> Void
    
    // 0-5점 이모지와 설명
    private let ratingEmojis = ["😤", "😕", "😐", "🙂", "😊", "🤩"]
    private let ratingDescriptions = ["매우 싫어함", "싫어함", "별로", "괜찮음", "좋아함", "매우 좋아함"]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(note)
                    .font(.subheadline)
                    .bold()
                
                Spacer()
                
                Text(ratingDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                ForEach(0...5, id: \.self) { score in
                    Button(action: {
                        onRatingChanged(score)
                    }) {
                        VStack(spacing: 2) {
                            Text(ratingEmojis[score])
                                .font(.title2)
                                .scaleEffect(score == rating ? 1.2 : 1.0)
                                .opacity(score == rating ? 1.0 : 0.6)
                            
                            Text("\(score)")
                                .font(.caption2)
                                .foregroundColor(score == rating ? .accentColor : .gray)
                                .bold(score == rating)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: rating)
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var ratingDescription: String {
        guard rating >= 0 && rating < ratingDescriptions.count else {
            return "보통"
        }
        return ratingDescriptions[rating]
    }
}

// MARK: - 최종 분석 화면
struct FinalAnalysisScreen: View {
    let projectName: String
    let userNoteRatings: [String: Int]
    let isLoading: Bool
    let error: Error?
    let onBack: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 0) {
                        Image(systemName: "chevron.left")
                        Text("뒤로")
                    }
                    .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text("최종 분석")
                    .font(.headline)
                    .bold()
                
                Spacer()
                
                Color.clear
                    .frame(width: 60)
            }
            .padding(.horizontal)
            .padding(.top, 0)
            .padding(.bottom, 0)
            
            Spacer()
            
            if isLoading {
                VStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("AI가 당신만의 향수를 찾고 있습니다...")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("향 노트 평가를 바탕으로\n완벽한 매칭을 진행중입니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if let error = error {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("분석 중 오류가 발생했습니다")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button("다시 시도") {
                        onRetry()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding()
            }
            
            Spacer()
        }
    }
}

// MARK: - 향수 추천 카드 컴포넌트
struct PerfumeRecommendationCard: View {
    let perfume: Perfume
    let rank: Int
    let showDetailedInfo: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 상단: 순위, 이름, 브랜드
            HStack(spacing: 12) {
                // 순위 배지
                ZStack {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 40, height: 40)
                    
                    Text("\(rank)")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                }
                
                // 향수 정보
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(perfume.brand)")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text("\(perfume.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 매치 점수
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.caption)
                        
                        Text("매치도 \(String(format: "%.1f", perfume.similarity * 100))%")
                            .font(.caption)
                            .foregroundColor(.pink)
                    }
                }
                
                Spacer()
                
                // 향수 이미지
                AsyncImage(url: URL(string: perfume.imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .font(.title2)
                                    Text("이미지 로드 실패")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            )
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .tint(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            )
                    }
                }
                .frame(width: 60, height: 80)
                .cornerRadius(8)
                .clipped()
            }
            
            // 감정 태그 표시
            if !(perfume.emotionTags.isEmpty) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🎯 감정 특성")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.purple)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(perfume.emotionTags.prefix(4), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // 향수 설명 (상세 정보 포함)
            if showDetailedInfo && !(perfume.description.isEmpty) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💭 AI 추천 분석")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.green)
                    
                    Text(perfume.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(6)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
                .background(Color.green.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color.brown
        default: return .purple
        }
    }
}

// MARK: - 추천 진단 카드
struct RecommendationDiagnosisCard: View {
    let diagnosis: RecommendationDiagnosis
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 상단: 간단한 진단 결과 - 더 컴팩트하게
            HStack(spacing: 8) {
                Text(diagnosis.recommendationQuality.emoji)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("추천 품질 분석")
                        .font(.caption)
                        .bold()
                        .foregroundColor(diagnosis.recommendationQuality.color)
                    
                    Text("중복도: \(String(format: "%.1f", diagnosis.overlapPercentage))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                }
            }
            
            // 확장된 상세 정보
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                    
                    // 중복도 상세 정보
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📊 상세 분석")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.blue)
                        
                        HStack {
                            Text("• 1차 추천:")
                            Spacer()
                            Text("\(diagnosis.totalFirstRecommendations)개")
                        }
                        .font(.caption2)
                        
                        HStack {
                            Text("• 2차 추천:")
                            Spacer()
                            Text("\(diagnosis.totalSecondRecommendations)개")
                        }
                        .font(.caption2)
                        
                        HStack {
                            Text("• 동일한 향수:")
                            Spacer()
                            Text("\(diagnosis.overlapCount)개")
                        }
                        .font(.caption2)
                        .foregroundColor(.red)
                    }
                    
                    // 진단 메시지
                    if diagnosis.isProblematic {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⚠️ 문제점")
                                .font(.caption2)
                                .bold()
                                .foregroundColor(.red)
                            
                            Text(diagnosis.diagnosisMessage)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            
                            Text("💡 해결책: 향 노트 평가를 더 극단적으로 해보세요")
                                .font(.caption2)
                                .foregroundColor(.green)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(12)
        .background(diagnosis.recommendationQuality.color.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(diagnosis.recommendationQuality.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 추천 진단 결과 모델
struct RecommendationDiagnosis {
    let overlapPercentage: Double
    let overlapCount: Int
    let totalFirstRecommendations: Int
    let totalSecondRecommendations: Int
    let isProblematic: Bool
    let diagnosisMessage: String
    let recommendationQuality: RecommendationQuality
    
    enum RecommendationQuality {
        case excellent, good, fair, poor, critical
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            case .critical: return .purple
            }
        }
        
        var emoji: String {
            switch self {
            case .excellent: return "🎯"
            case .good: return "✅"
            case .fair: return "⚠️"
            case .poor: return "❌"
            case .critical: return "💥"
            }
        }
    }
}

