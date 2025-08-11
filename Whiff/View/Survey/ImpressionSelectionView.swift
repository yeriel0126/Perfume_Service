import SwiftUI

struct ImpressionSelectionView: View {
    @Binding var selectedImpressions: Set<String>
    var onNext: () -> Void
    var onBack: () -> Void

    let impressions: [Option] = [
        .init(name: "Confident", imageName: "confident_img"),
        .init(name: "Elegant", imageName: "elegant_img"),
        .init(name: "Pure", imageName: "pure_img"),
        .init(name: "Friendly", imageName: "friendly_img"),
        .init(name: "Mysterious", imageName: "mysterious_img"),
        .init(name: "Fresh", imageName: "fresh_img")
    ]

    var body: some View {
        MultipleSelectionGridView(
            options: impressions,
            selectedOptions: $selectedImpressions,
            title: "어떤 인상을 주고 싶으신가요?",
            subtitle: "2가지 매력을 선택해주세요\n선택하신 조합은 AI가 최적화해드립니다",
            requiredCount: 2,
            onNext: onNext,
            onBack: onBack
        )
    }
} 
