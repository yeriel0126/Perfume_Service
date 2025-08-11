import SwiftUI

// MARK: - 모델 정보 시트

struct ModelInfoSheet: View {
    @ObservedObject var projectStore: ProjectStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // ❌ 일반 모델 정보 제거
                    
                    // AI 추천 모델 정보만 표시
                    ModelInfoCard(
                        title: "AI 추천 모델",  // 변경: "클러스터 추천 모델 (신규)" → "AI 추천 모델"
                        description: "감정 클러스터링 기술을 활용한 고도화된 개인 맞춤 추천 시스템입니다.",
                        features: [
                            "🧠 딥러닝 기반 분석",
                            "🎨 감정 태그 예측",
                            "📈 학습 데이터 활용",
                            "🚀 개인화 정확도 향상"
                        ],
                        status: "사용 가능",  // 변경: 조건부 → 항상 "사용 가능"
                        statusColor: .green
                    )
                }
                .padding()
                .background(Color.whiffMainBackground)
            }
            .navigationTitle("추천 모델 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundColor(.whiffPrimary)
                }
            }
        }
    }
}

// MARK: - 모델 정보 카드

struct ModelInfoCard: View {
    let title: String
    let description: String
    let features: [String]
    let status: String
    let statusColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.whiffPrimaryText)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.whiffWhiteText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(8)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.whiffSecondaryText2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("주요 특징")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.whiffPrimaryText)
                
                ForEach(features, id: \.self) { feature in
                    Text(feature)
                        .font(.caption)
                        .foregroundColor(.whiffSecondaryText2)
                }
            }
        }
        .padding()
        .background(Color.whiffSectionBackground)
        .cornerRadius(16)
    }
} 
