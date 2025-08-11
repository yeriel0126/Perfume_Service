import SwiftUI

struct TasteAnalysisLoadingView: View {
    let projectName: String
    let projectId: UUID
    let preferences: PerfumePreferences
    
    @StateObject private var viewModel = TasteAnalysisViewModel()
    @State private var currentStep: LoadingStep = .initial
    
    enum LoadingStep {
        case initial
        case firstRecommendation
        case completed
    }
    
    var body: some View {
        ZStack {
            // 배경
            Color.white.ignoresSafeArea()
            
            // 콘텐츠
            VStack(spacing: 0) {
                switch currentStep {
                case .initial:
                    initialView
                case .firstRecommendation:
                    firstRecommendationView
                case .completed:
                    completedView
                }
                
                Spacer()
            }
        }
        .onAppear {
            if currentStep == .initial {
                currentStep = .firstRecommendation
                Task {
                    await performFirstRecommendation()
                }
            }
        }
    }
    
    // MARK: - 초기 화면
    
    private var initialView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.whiffPrimary)
                
                Text("취향 분석 준비")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.whiffPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("당신의 향수 취향을\n분석할 준비가 되었습니다")
                    .font(.subheadline)
                    .foregroundColor(.whiffSecondaryText2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.whiffMainBackground)
    }

    // MARK: - 1차 추천 단계
    
    private var firstRecommendationView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.whiffPrimary)
                    .rotationEffect(.degrees(viewModel.isAnalyzing ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: viewModel.isAnalyzing)
                
                Text("감정 클러스터 분석 중")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.whiffPrimaryText)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    Text("당신의 설문 응답을 바탕으로\n감정 클러스터를 찾고\n초기 향수를 선별하고 있습니다")
                        .font(.subheadline)
                        .foregroundColor(.whiffSecondaryText2)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    // 재시도 상태 표시
                    if viewModel.currentAttempt > 0 {
                        Text("재시도 중... (\(viewModel.currentAttempt)/3)")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                    }
                    
                    // 에러 메시지 표시
                    if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 8) {
                            Text("⚠️ 연결 문제가 발생했습니다")
                                .font(.caption)
                                .foregroundColor(.red)
                                .bold()
                            
                            Text(errorMessage)
                                .font(.caption2)
                                .foregroundColor(.whiffSecondaryText2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            if viewModel.isAnalyzing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    .scaleEffect(1.5)
                    .padding(.bottom, 50)
            }
        }
        .padding()
        .background(Color.whiffMainBackground)
    }
    
    // MARK: - 완료 단계
    
    private var completedView: some View {
        VStack(spacing: 32) {
            // 성공 아이콘
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.whiffSecondaryText1)
                
                VStack(spacing: 8) {
                    Text("분석 완료!")
                        .font(.title)
                        .bold()
                    
                    Text("당신만의 향수를 찾았습니다")
                        .font(.subheadline)
                        .foregroundColor(.whiffSecondaryText2)
                }
            }
            
            // 네비게이션 링크
            NavigationLink(destination: FinalRecommendationView(
                projectName: projectName,
                firstRecommendationData: viewModel.firstRecommendationData,
                userPreferences: preferences
            )) {
                Text("결과 보기")
                    .font(.headline)
                    .foregroundColor(.whiffWhiteText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.whiffPrimary)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - 분석 시작
    
    private func startAnalysis() {
        Task {
            await performFirstRecommendation()
        }
    }
    
    private func performFirstRecommendation() async {
        print("🚀 [새로운 플로우] 1차 추천 시작")
        await viewModel.getFirstRecommendation(preferences: preferences)
        
        if viewModel.firstRecommendationData != nil {
            print("✅ [1차 추천 완료] FinalRecommendationView로 이동")
            currentStep = .completed
        }
    }
}

// MARK: - 선호도 칩 컴포넌트
struct PreferenceChip: View {
    let label: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.whiffPrimary.opacity(0.1))
        .cornerRadius(8)
        .foregroundColor(.whiffPrimary)
    }
}

// MARK: - 뷰모델 간소화
@MainActor
class TasteAnalysisViewModel: ObservableObject {
    @Published var recommendedPerfumes: [Perfume] = []
    @Published var isAnalyzing = true
    @Published var firstRecommendationData: FirstRecommendationResponse?
    @Published var currentAttempt = 0
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    func getFirstRecommendation(preferences: PerfumePreferences) async {
        print("🚀 [1차 추천] API 호출 시작")
        print("📋 [설문 응답] \(preferences.description)")
        
        await MainActor.run {
            isAnalyzing = true
            currentAttempt = 0
            errorMessage = nil
        }
        
        do {
            // 재시도 로직이 포함된 1차 추천 API 호출
            let firstRecommendationResponse = try await networkManager.getFirstRecommendations(preferences: preferences) { attempt in
                // 재시도 상태 업데이트를 위한 클로저
                await MainActor.run {
                    self.currentAttempt = attempt
                    if attempt > 1 {
                        self.errorMessage = "서버 응답이 느립니다. 재시도 중입니다..."
                    }
                }
            }
            
            await MainActor.run {
                firstRecommendationData = firstRecommendationResponse
                isAnalyzing = false
                currentAttempt = 0
                errorMessage = nil
            }
            
            print("✅ [1차 추천 성공] 클러스터: \(firstRecommendationResponse.clusterInfo?.cluster ?? -1)")
            
        } catch {
            await MainActor.run {
                isAnalyzing = false
                currentAttempt = 0
                
                // 에러 타입별 메시지 설정
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .timedOut:
                        errorMessage = "서버 응답 시간이 초과되었습니다.\nRender 서버가 시작 중일 수 있습니다."
                    case .notConnectedToInternet:
                        errorMessage = "인터넷 연결을 확인해주세요."
                    case .cannotConnectToHost:
                        errorMessage = "서버에 연결할 수 없습니다."
                    default:
                        errorMessage = "네트워크 오류가 발생했습니다."
                    }
                } else {
                    errorMessage = "알 수 없는 오류가 발생했습니다."
                }
            }
            print("❌ [1차 추천 실패] \(error)")
        }
    }
    
    func getSecondRecommendation(
        userPreferences: PerfumePreferences,
        userNoteScores: [String: Int],
        emotionProba: [Double],
        selectedIdx: [Int]
    ) async {
        print("🎯 [2차 추천] 실제 사용자 데이터로 API 호출")
        
        await MainActor.run {
            isAnalyzing = true
        }
        
        do {
            let secondRecommendations = try await networkManager.getSecondRecommendations(
                userPreferences: userPreferences,
                userNoteScores: userNoteScores,
                emotionProba: emotionProba,
                selectedIdx: selectedIdx
            )
            
            // SecondRecommendationItem을 Perfume으로 변환
            let perfumes = secondRecommendations.map { $0.toPerfume() }
            
            await MainActor.run {
                recommendedPerfumes = perfumes
                isAnalyzing = false
            }
            
            print("✅ [2차 추천 성공] \(perfumes.count)개 향수")
            
        } catch {
            await MainActor.run {
                isAnalyzing = false
            }
            print("❌ [2차 추천 실패] \(error)")
        }
    }
}

#Preview {
    TasteAnalysisLoadingView(
        projectName: "테스트 프로젝트",
        projectId: UUID(),
        preferences: PerfumePreferences(
            gender: "남성",
            seasonTags: "봄",
            timeTags: "낮",
            desiredImpression: "신선한",
            activity: "일상",
            weather: "맑음"
        )
    )
    .environmentObject(ProjectStore())
} 
