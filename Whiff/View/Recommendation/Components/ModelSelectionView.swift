import SwiftUI

// MARK: - 모델 선택 섹션

struct ModelSelectionView: View {
    @Binding var selectedModel: RecommendationModelType
    @ObservedObject var projectStore: ProjectStore
    @Binding var showingModelInfo: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("추천 모델 선택")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.whiffPrimaryText)
                
                Spacer()
                
                Button(action: {
                    showingModelInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.whiffPrimary)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(RecommendationModelType.allCases, id: \.self) { model in
                    ModelOptionCard(
                        model: model,
                        isSelected: selectedModel == model,
                        isAvailable: model == .standard || projectStore.isNewModelAvailable(),
                        onSelect: {
                            selectedModel = model
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.whiffSectionBackground)
        .cornerRadius(16)
    }
}

// MARK: - 모델 옵션 카드

struct ModelOptionCard: View {
    let model: RecommendationModelType
    let isSelected: Bool
    let isAvailable: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            if isAvailable {
                onSelect()
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: model.icon)
                    .font(.title2)
                    .foregroundColor(isAvailable ? .whiffPrimary : .whiffSecondaryText2)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(model.rawValue)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(isAvailable ? .whiffPrimaryText : .whiffSecondaryText2)
                        
                        if model == .cluster && isAvailable {
                            Text("NEW")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.whiffWhiteText)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.whiffPrimary)
                                .cornerRadius(4)
                        }
                        
                        if !isAvailable {
                            Text("준비중")
                                .font(.caption)
                                .foregroundColor(.whiffSecondaryText2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.whiffSecondaryText2.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(isAvailable ? .whiffSecondaryText2 : .whiffSecondaryText2)
                }
                
                Spacer()
                
                if isSelected && isAvailable {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.whiffPrimary)
                }
            }
            .padding()
            .background(
                isSelected && isAvailable ? Color.whiffPrimary.opacity(0.1) : Color.whiffMainBackground
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected && isAvailable ? Color.whiffPrimary : Color.whiffSecondaryText2.opacity(0.3),
                        lineWidth: isSelected && isAvailable ? 2 : 1
                    )
            )
            .cornerRadius(12)
        }
        .disabled(!isAvailable)
    }
}

// MARK: - 추천 시작 버튼

struct RecommendationStartButton: View {
    let selectedModel: RecommendationModelType
    let isModelHealthy: Bool
    
    private var isDisabled: Bool {
        selectedModel == .cluster && !isModelHealthy
    }
    
    private var buttonText: String {
        if isDisabled {
            return "새로운 모델 준비중..."
        }
        return selectedModel.buttonText
    }
    
    var body: some View {
        HStack {
            Image(systemName: isDisabled ? "clock" : "plus.circle.fill")
            Text(buttonText)
                .bold()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isDisabled ? Color.whiffSecondaryText2.opacity(0.3) : Color.whiffPrimary.opacity(0.1))
        .foregroundColor(isDisabled ? .whiffSecondaryText2 : .whiffPrimary)
        .cornerRadius(12)
    }
} 
