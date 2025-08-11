import SwiftUI

struct GenderSelectionView: View {
    @Binding var selectedGender: String?
    var onNext: () -> Void

    let genders: [Option] = [
        .init(name: "Male", imageName: "male_img"),
        .init(name: "Female", imageName: "female_img"),
        .init(name: "Unisex", imageName: "unisex_img")
    ]

    var body: some View {
        SelectionGridView(
            options: genders,
            selectedOption: $selectedGender,
            title: "어떤 향의 느낌을 더 원하시나요?",
            onNext: onNext,
            onBack: nil
        )
    }
}
