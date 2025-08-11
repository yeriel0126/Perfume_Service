import SwiftUI

struct TimeSelectionView: View {
    @Binding var selectedTime: String?
    var onNext: () -> Void
    var onBack: () -> Void

    let times: [Option] = [
        .init(name: "Day", imageName: "day_img"),
        .init(name: "Night", imageName: "night_img")
    ]

    var body: some View {
        SelectionGridView(
            options: times,
            selectedOption: $selectedTime,
            title: "어느 시간대에 향수를 자주 사용하시나요?",
            onNext: onNext,
            onBack: onBack
        )
    }
}
