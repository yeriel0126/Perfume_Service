import SwiftUI

struct RecommendationCardView: View {
    let perfume: Perfume
    let matchScore: Int
    
    @State private var detailedPerfume: Perfume?
    @State private var isLoadingDetails = false
    
    private let networkManager = NetworkManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 상단 정보 (이미지 + 기본 정보)
            HStack(spacing: 16) {
                // 향수 이미지 (크기 조정)
                AsyncImage(url: URL(string: perfume.imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 160)
                            .clipped()
                            .cornerRadius(8)
                    case .failure(let error):
                        // 이미지 로딩 실패 시 향수 이름의 첫 글자를 표시
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.whiffPrimary.opacity(0.7), .whiffPrimary]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 140, height: 160)
                            .cornerRadius(8)
                            .overlay(
                                VStack(spacing: 4) {
                                    Text(String(perfume.name.prefix(1)))
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.whiffWhiteText)
                                    Text(perfume.brand)
                                        .font(.caption2)
                                        .foregroundColor(.whiffWhiteText.opacity(0.8))
                                        .lineLimit(1)
                                }
                            )
                            .onAppear {
                                print("❌ [이미지 로딩 실패] \(perfume.name) - URL: '\(perfume.imageURL)' - 오류: \(error)")
                            }
                    case .empty:
                        Rectangle()
                            .fill(Color.whiffSecondaryText2.opacity(0.1))
                            .frame(width: 140, height: 160)
                            .cornerRadius(8)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.0)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // 향수 기본 정보
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(perfume.brand)
                            .font(.caption)
                            .foregroundColor(.whiffPrimary)
                            .bold()

                        Text(perfume.name)
                            .font(.subheadline)
                            .bold()
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack {
                        Text("Match")
                            .font(.caption2)
                            .foregroundColor(.whiffSecondaryText2)
                        Text("\(matchScore)%")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.whiffPrimary)
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
            
            // 향조 구성 섹션 (별도 영역으로 분리)
            VStack(alignment: .leading, spacing: 12) {
                Text("향조 구성")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.whiffPrimaryText)
                
                let displayPerfume = detailedPerfume ?? perfume
                
                if isLoadingDetails {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("향조 정보를 불러오는 중...")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if hasNotes(displayPerfume) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Top Notes
                        if !displayPerfume.notes.top.isEmpty {
                            NoteSection(title: "Top", notes: displayPerfume.notes.top, color: .green)
                        }
                        
                        // Middle Notes
                        if !displayPerfume.notes.middle.isEmpty {
                            NoteSection(title: "Middle", notes: displayPerfume.notes.middle, color: .orange)
                        }
                        
                        // Base Notes
                        if !displayPerfume.notes.base.isEmpty {
                            NoteSection(title: "Base", notes: displayPerfume.notes.base, color: .purple)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("향조 정보를 찾을 수 없습니다")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                            .italic()
                        
                        Text("이 향수의 상세 정보가 아직 업데이트되지 않았습니다.")
                            .font(.caption2)
                            .foregroundColor(.whiffSecondaryText2.opacity(0.8))
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color.whiffMainBackground)
        .cornerRadius(16)
        .shadow(color: .whiffPrimaryText.opacity(0.1), radius: 4, x: 0, y: 2)
        .id(perfume.id)
        .onAppear {
            loadDetailedInfoIfNeeded()
        }
        .onChange(of: perfume.id) { _, newPerfumeId in
            detailedPerfume = nil
            isLoadingDetails = false
            loadDetailedInfoIfNeeded()
            print("🔄 [향조 업데이트] 새로운 향수로 변경: \(perfume.name)")
        }
    }
    
    private func hasNotes(_ perfume: Perfume) -> Bool {
        return !perfume.notes.top.isEmpty || !perfume.notes.middle.isEmpty || !perfume.notes.base.isEmpty
    }
    
    private func loadDetailedInfoIfNeeded() {
        // 이미 노트 정보가 있거나 로딩 중이면 스킵
        guard !hasNotes(perfume) && !isLoadingDetails else { return }
        
        isLoadingDetails = true
        
        Task {
            do {
                let detailed = try await networkManager.fetchPerfumeDetail(name: perfume.name)
                await MainActor.run {
                    self.detailedPerfume = detailed
                    self.isLoadingDetails = false
                    print("✅ [향조 정보] \(perfume.name) 상세 정보 로딩 완료")
                }
            } catch {
                await MainActor.run {
                    self.isLoadingDetails = false
                    print("❌ [향조 정보] \(perfume.name) 상세 정보 로딩 실패: \(error)")
                }
            }
        }
    }
}

// MARK: - 노트 섹션 컴포넌트
struct NoteSection: View {
    let title: String
    let notes: [String]
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                
                Text(title)
                    .font(.caption)
                    .bold()
                    .foregroundColor(color)
                    .frame(width: 45, alignment: .leading)
            }
            
            Text(notes.prefix(4).joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.whiffSecondaryText2)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    RecommendationCardView(
        perfume: Perfume(
            id: "test",
            name: "1 Million Lucky",
            brand: "Paco Rabanne",
            imageURL: "https://example.com/image.jpg",
            price: 120000,
            description: "Test description",
            notes: PerfumeNotes(
                top: ["Bergamot", "Lemon", "Grapefruit"],
                middle: ["Jasmine", "Rose", "Lily"],
                base: ["Sandalwood", "Musk", "Vanilla"]
            ),
            rating: 4.5,
            emotionTags: ["신선한", "시트러스"],
            similarity: 0.85
        ),
        matchScore: 87
    )
    .padding()
    .background(Color.whiffMainBackground)
}
