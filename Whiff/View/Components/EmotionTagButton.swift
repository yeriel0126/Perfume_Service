import SwiftUI

struct EmotionTagButton: View {
    let tag: EmotionTag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tag.name)
                        .font(.subheadline)
                        .bold()
                    Text("(\(Int(tag.confidence * 100))%)")
                        .font(.caption)
                        .foregroundColor(.whiffSecondaryText2)
                }
                
                if let category = tag.category {
                    Text(category)
                        .font(.caption2)
                        .foregroundColor(.whiffSecondaryText2)
                }
                
                if let description = tag.description {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.whiffSecondaryText2)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.whiffPrimary : Color.whiffSectionBackground)
            .foregroundColor(isSelected ? Color.whiffWhiteText : Color.whiffSecondaryText2)
            .cornerRadius(16)
        }
    }
}

