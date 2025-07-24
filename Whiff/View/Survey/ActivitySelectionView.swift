import SwiftUI

struct ActivitySelectionView: View {
    @Binding var selectedActivity: String?
    var onNext: () -> Void
    var onBack: () -> Void

    let activities: [Option] = [
        .init(name: "Casual", imageName: "casual_img"),
        .init(name: "Work", imageName: "work_img"),
        .init(name: "Date", imageName: "date_img")
    ]

    var body: some View {
        SelectionGridView(
            options: activities,
            selectedOption: $selectedActivity,
            title: "어떤 상황에서 사용할 향인가요?",
            onNext: onNext,
            onBack: onBack
        )
    }
} 