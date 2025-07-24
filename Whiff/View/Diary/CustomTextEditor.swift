import SwiftUI

struct CustomTextEditor: View {
    @Binding var text: String

    var body: some View {
        TextEditor(text: $text)
            .padding(12)
            .background(Color.whiffSectionBackground)
            .cornerRadius(8) // 12에서 8로 변경
            .overlay(
                RoundedRectangle(cornerRadius: 8) // 12에서 8로 변경
                    .stroke(Color.whiffPrimary.opacity(0.5), lineWidth: 1) // 색상과 투명도 변경
            )
            .foregroundColor(.whiffPrimaryText)
            .font(.body)
    }
}
