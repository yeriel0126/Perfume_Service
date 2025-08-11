import SwiftUI

struct PerfumePreferenceSurveyView: View {
    let projectName: String
    @StateObject private var viewModel = PerfumePreferenceSurveyViewModel()
    @EnvironmentObject var projectStore: ProjectStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 진행률 표시 - Navigation Title과 겹치지 않게 간격 조정
                VStack(spacing: 8) {
                    ProgressView(value: Double(viewModel.currentStep), total: Double(viewModel.totalSteps))
                        .progressViewStyle(LinearProgressViewStyle(tint: .whiffPrimary))
                        .padding(.horizontal)
                    
                    Text("\(viewModel.currentStep)/\(viewModel.totalSteps)")
                        .font(.caption)
                        .foregroundColor(.whiffSecondaryText2)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // 현재 단계 화면 - SafeArea 처리
                Group {
                    switch viewModel.currentStep {
                    case 1:
                        GenderSelectionView(
                            selectedGender: $viewModel.selectedGender,
                            onNext: viewModel.nextStep
                        )
                    case 2:
                        SeasonSelectionView(
                            selectedSeason: $viewModel.selectedSeason,
                            onNext: viewModel.nextStep,
                            onBack: viewModel.previousStep
                        )
                    case 3:
                        ActivitySelectionView(
                            selectedActivity: $viewModel.selectedActivity,
                            onNext: viewModel.nextStep,
                            onBack: viewModel.previousStep
                        )
                    case 4:
                        TimeSelectionView(
                            selectedTime: $viewModel.selectedTime,
                            onNext: viewModel.nextStep,
                            onBack: viewModel.previousStep
                        )
                    case 5:
                        ImpressionSelectionView(
                            selectedImpressions: $viewModel.selectedImpressions,
                            onNext: viewModel.nextStep,
                            onBack: viewModel.previousStep
                        )
                    case 6:
                        WeatherSelectionView(
                            selectedWeather: $viewModel.selectedWeather,
                            onNext: viewModel.completeSurvey,
                            onBack: viewModel.previousStep
                        )
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(projectName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $viewModel.surveyCompleted) {
                TasteAnalysisLoadingView(
                    projectName: projectName,
                    projectId: UUID(),
                    preferences: PerfumePreferences(
                        gender: viewModel.selectedGender ?? "",
                        seasonTags: viewModel.selectedSeason ?? "",
                        timeTags: viewModel.selectedTime ?? "",
                        desiredImpression: viewModel.combinedImpression,
                        activity: viewModel.selectedActivity ?? "",
                        weather: viewModel.selectedWeather ?? ""
                    )
                )
                .environmentObject(projectStore)
            }
            .task {
                await viewModel.loadPerfumes()
            }
        }
    }
}

// MARK: - View Model
@MainActor
class PerfumePreferenceSurveyViewModel: ObservableObject {
    @Published var currentStep = 1
    @Published var selectedGender: String?
    @Published var selectedSeason: String?
    @Published var selectedActivity: String?
    @Published var selectedTime: String?
    @Published var selectedImpressions: Set<String> = []
    @Published var selectedWeather: String?
    @Published var recommendedPerfumes: [Perfume] = []
    @Published var surveyCompleted = false
    
    let totalSteps = 6
    private let networkManager = NetworkManager.shared
    
    // computed property로 2개 인상을 조합한 문자열 반환
    var combinedImpression: String {
        let impressionArray = Array(selectedImpressions).sorted()
        return impressionArray.joined(separator: ", ").lowercased()
    }
    
    func nextStep() {
        if currentStep < totalSteps {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    func completeSurvey() {
        // 설문 완료 후 취향 분석 로딩 화면으로 이동
        print("🎯 Survey completed! Moving to loading screen...")
        print("📝 선택된 응답들:")
        print("   성별: \(selectedGender ?? "nil")")
        print("   계절: \(selectedSeason ?? "nil")")
        print("   활동: \(selectedActivity ?? "nil")")
        print("   시간: \(selectedTime ?? "nil")")
        print("   인상: \(Array(selectedImpressions).joined(separator: ", "))")
        print("   조합된 인상: \(combinedImpression)")
        print("   날씨: \(selectedWeather ?? "nil")")
        
        // @MainActor 클래스이므로 직접 설정
        surveyCompleted = true
        print("✅ surveyCompleted 설정됨: \(surveyCompleted)")
    }
    
    func loadPerfumes() async {
        do {
            let fetchedPerfumes = try await networkManager.fetchPerfumes()
            
            // API 데이터에 노트 정보가 있는지 확인
            let perfumesWithNotes = fetchedPerfumes.filter { perfume in
                !perfume.notes.top.isEmpty || !perfume.notes.middle.isEmpty || !perfume.notes.base.isEmpty
            }
            
            if perfumesWithNotes.isEmpty {
                // API 데이터에 노트 정보가 없으면 샘플 데이터 사용
                print("⚠️ [설문조사] API 데이터에 노트 정보가 없어 샘플 데이터 사용")
                recommendedPerfumes = PerfumeDataUtils.createRealisticPerfumes()
            } else {
                recommendedPerfumes = perfumesWithNotes
            }
            
            print("✅ [설문조사] \(recommendedPerfumes.count)개 향수 로드 완료")
        } catch {
            print("❌ [설문조사] 향수 로딩 실패: \(error)")
            // API 실패 시 샘플 데이터 사용
            recommendedPerfumes = PerfumeDataUtils.createRealisticPerfumes()
        }
    }
}

struct PerfumePreferenceSurveyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PerfumePreferenceSurveyView(projectName: "테스트 프로젝트")
        }
        .environmentObject(ProjectStore())
    }
}
