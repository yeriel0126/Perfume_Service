import SwiftUI

struct SelectionGridView: View {
    let options: [Option]
    @Binding var selectedOption: String?
    let title: String
    let subtitle: String?
    let onNext: () -> Void
    var onBack: (() -> Void)? = nil

    // 3열 그리드로 변경하여 더 균형잡힌 배치
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // subtitle이 없는 경우를 위한 편의 초기화
    init(options: [Option], selectedOption: Binding<String?>, title: String, onNext: @escaping () -> Void, onBack: (() -> Void)? = nil) {
        self.options = options
        self._selectedOption = selectedOption
        self.title = title
        self.subtitle = nil
        self.onNext = onNext
        self.onBack = onBack
    }
    
    // subtitle이 있는 경우를 위한 초기화
    init(options: [Option], selectedOption: Binding<String?>, title: String, subtitle: String?, onNext: @escaping () -> Void, onBack: (() -> Void)? = nil) {
        self.options = options
        self._selectedOption = selectedOption
        self.title = title
        self.subtitle = subtitle
        self.onNext = onNext
        self.onBack = onBack
    }

    var body: some View {
        VStack(spacing: 0) {
            // 질문 텍스트 - 상단 고정
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.horizontal)
                
                // 부제목이 있는 경우에만 표시
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.whiffSecondaryText2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 32)

            // 선택지 그리드 - 안정감 있는 3x2 레이아웃
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(options) { option in
                    Button(action: {
                        selectedOption = option.name
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                // 이미지 배경
                                Image(option.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(16)
                                    .overlay(
                                        // 반투명 오버레이로 텍스트 가독성 향상
                                        Rectangle()
                                            .fill(Color.whiffPrimaryText.opacity(0.3))
                                            .cornerRadius(16)
                                    )
                                
                                // 텍스트
                                Text(option.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.whiffWhiteText)
                                    .multilineTextAlignment(.center)
                                    .shadow(color: .whiffPrimaryText.opacity(0.8), radius: 1, x: 0, y: 1)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        selectedOption == option.name ? Color.whiffPrimary : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                            .scaleEffect(selectedOption == option.name ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: selectedOption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // 버튼 영역 - SafeArea 처리
            HStack(spacing: 16) {
                if let onBack = onBack {
                    Button(action: onBack) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("이전")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(Color.whiffSectionBackground.opacity(0.2))
                        .foregroundColor( .whiffPrimaryText)
                        .cornerRadius(12)
                    }
                }

                Button(action: {
                    if selectedOption != nil {
                        onNext()
                    }
                }) {
                    Text("다음")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(selectedOption != nil ? Color.whiffPrimary : Color.whiffSecondaryText2.opacity(0.3))
                        .foregroundColor(.whiffWhiteText)
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
                .disabled(selectedOption == nil)
                .animation(.easeInOut(duration: 0.2), value: selectedOption)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Multiple Selection Grid View

struct MultipleSelectionGridView: View {
    let options: [Option]
    @Binding var selectedOptions: Set<String>
    let title: String
    let subtitle: String?
    let requiredCount: Int
    let onNext: () -> Void
    var onBack: (() -> Void)? = nil

    // 3열 그리드로 변경하여 더 균형잡힌 배치
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 질문 텍스트 - 상단 고정
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.horizontal)
                
                // 부제목이 있는 경우에만 표시
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.whiffSecondaryText2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // 선택 개수 표시
                Text("\(selectedOptions.count)/\(requiredCount) 선택됨")
                    .font(.caption)
                    .foregroundColor(selectedOptions.count == requiredCount ? .green : .whiffSecondaryText2)
                    .fontWeight(selectedOptions.count == requiredCount ? .semibold : .regular)
            }
            .padding(.bottom, 32)

            // 선택지 그리드 - 안정감 있는 3x2 레이아웃
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(options) { option in
                    Button(action: {
                        toggleSelection(for: option.name)
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                // 이미지 배경
                                Image(option.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(16)
                                    .overlay(
                                        // 반투명 오버레이로 텍스트 가독성 향상
                                        Rectangle()
                                            .fill(Color.whiffPrimaryText.opacity(0.3))
                                            .cornerRadius(16)
                                    )
                                    .overlay(
                                        // 선택 시 파란색 테두리 (이미지 크기와 정확히 맞춤)
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                selectedOptions.contains(option.name) ? Color.whiffPrimary : Color.clear, 
                                                lineWidth: 3
                                            )
                                    )
                                
                                // 텍스트
                                Text(option.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.whiffWhiteText)
                                    .multilineTextAlignment(.center)
                                    .shadow(color: .whiffPrimaryText.opacity(0.8), radius: 1, x: 0, y: 1)
                                
                                // 선택 표시 (체크마크)
                                if selectedOptions.contains(option.name) {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.whiffWhiteText)
                                                .background(Circle().fill(Color.whiffPrimary))
                                                .clipShape(Circle())
                                        }
                                        Spacer()
                                    }
                                    .padding(8)
                                }
                            }
                            .scaleEffect(selectedOptions.contains(option.name) ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: selectedOptions.contains(option.name))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // 버튼 영역 - SafeArea 처리
            HStack(spacing: 16) {
                if let onBack = onBack {
                    Button(action: onBack) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("이전")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(Color.whiffSectionBackground.opacity(0.2))
                        .foregroundColor( .whiffPrimaryText)
                        .cornerRadius(12)
                    }
                }

                Button(action: {
                    if selectedOptions.count == requiredCount {
                        onNext()
                    }
                }) {
                    Text("다음")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(selectedOptions.count == requiredCount ? Color.whiffPrimary : Color.whiffSecondaryText2.opacity(0.3))
                        .foregroundColor(.whiffWhiteText)
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
                .disabled(selectedOptions.count != requiredCount)
                .animation(.easeInOut(duration: 0.2), value: selectedOptions.count)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    private func toggleSelection(for option: String) {
        if selectedOptions.contains(option) {
            selectedOptions.remove(option)
        } else if selectedOptions.count < requiredCount {
            selectedOptions.insert(option)
        }
        // 이미 최대 개수만큼 선택된 경우 새로운 선택은 무시됨
    }
}
