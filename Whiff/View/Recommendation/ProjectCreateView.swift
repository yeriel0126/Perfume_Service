// ✅ ProjectCreateView.swift (iOS 16+ 최신 구조 적용)
import SwiftUI

struct ProjectCreateView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var projectName: String = ""
    @State private var goNext: Bool = false
    
    let selectedModel: RecommendationModelType
    
    init(selectedModel: RecommendationModelType = .standard) {
        self.selectedModel = selectedModel
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("프로젝트 이름을 입력해주세요")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("선택된 모델: \(selectedModel.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.whiffPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.whiffPrimary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            TextField("프로젝트 이름", text: $projectName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                NavigationLink(destination: PerfumePreferenceSurveyView(
                    projectName: projectName
                )) {
                    HStack {
                        Image(systemName: selectedModel.icon)
                        Text("일반 추천으로 시작하기")
                            .bold()
                    }
                    .foregroundColor(.whiffWhiteText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(projectName.isEmpty ? Color.whiffSecondaryText2 : Color.whiffPrimary)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(projectName.isEmpty)
                
                Text(selectedModel.description)
                    .font(.caption)
                    .foregroundColor(.whiffSecondaryText2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.whiffMainBackground)
        .navigationTitle("새 프로젝트")
        .navigationBarTitleDisplayMode(.inline)
    }
}
