import SwiftUI

struct SeasonSelectionView: View {
    @Binding var selectedSeason: String?
    var onNext: () -> Void
    var onBack: () -> Void

    let seasons: [Option] = [
        .init(name: "Spring", imageName: "spring_img"),
        .init(name: "Summer", imageName: "summer_img"),
        .init(name: "Fall", imageName: "fall_img"),
        .init(name: "Winter", imageName: "winter_img")
    ]

    var body: some View {
        SelectionGridView(
            options: seasons,
            selectedOption: $selectedSeason,
            title: "어느 계절에 어울리는 향을 찾고 싶나요?",
            onNext: onNext,
            onBack: onBack
        )
    }
}
