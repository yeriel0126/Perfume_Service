import SwiftUI

struct NoteEvaluationView: View {
    let extractedNotes: [String]
    let firstRecommendationData: FirstRecommendationResponse
    let userPreferences: PerfumePreferences
    let onComplete: ([String: Int]) -> Void
    
    @State private var noteRatings: [String: Int] = [:]
    @State private var currentNoteIndex = 0
    @State private var showScentGuide = false
    @Environment(\.presentationMode) var presentationMode
    
    private var currentNote: String {
        extractedNotes.isEmpty ? "" : extractedNotes[currentNoteIndex]
    }
    
    private var progress: Double {
        guard !extractedNotes.isEmpty else { return 0 }
        return Double(currentNoteIndex + 1) / Double(extractedNotes.count)
    }
    
    private var isLastNote: Bool {
        currentNoteIndex >= extractedNotes.count - 1
    }
    
    private var canProceed: Bool {
        noteRatings[currentNote] != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 진행 상황 표시
                VStack(spacing: 12) {
                    HStack {
                        Text("향 노트 평가")
                            .font(.title2)
                            .bold()
                        
                        Spacer()
                        
                        Text("\(currentNoteIndex + 1)/\(extractedNotes.count)")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .whiffPrimary))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
                .padding(.horizontal, 20)
                .padding(.top, 5)
                .padding(.bottom, 12)
                
                // 설명 텍스트
                VStack(spacing: 4) {
                    Text("당신의 1차 추천 향수들에서")
                        .font(.caption)
                        .foregroundColor(.whiffSecondaryText2)
                    
                    Text("자주 등장하는 향 노트들입니다")
                        .font(.caption)
                        .foregroundColor(.whiffSecondaryText2)
                    
                    Text("각 노트에 대한 선호도를 0-5점으로 평가해주세요")
                        .font(.caption2)
                        .foregroundColor(.whiffPrimary)
                        .bold()
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // 메인 컨텐츠 영역 (노트 평가) - Spacer 제거하고 직접 배치
                if !extractedNotes.isEmpty {
                    VStack(spacing: 28) {
                        // 노트 이름과 설명
                        VStack(spacing: 10) {
                            Text(currentNote)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.whiffPrimary)
                                .multilineTextAlignment(.center)
                            
                            Text(getNoteDescription(currentNote))
                                .font(.caption)
                                .foregroundColor(.whiffSecondaryText2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .lineLimit(2)
                        }
                        
                        // 평점 슬라이더 영역
                        VStack(spacing: 20) {
                            Text("이 노트를 얼마나 좋아하시나요?")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                            
                            VStack(spacing: 16) {
                                // 슬라이더
                                Slider(
                                    value: Binding(
                                        get: { Double(noteRatings[currentNote] ?? 3) },
                                        set: { noteRatings[currentNote] = Int(round($0)) }
                                    ),
                                    in: 0...5,
                                    step: 1
                                )
                                .accentColor(.whiffPrimary)
                                .padding(.horizontal, 20)
                                
                                // 슬라이더 라벨
                                HStack {
                                    Text("전혀 안 좋아함")
                                        .font(.caption2)
                                        .foregroundColor(.whiffSecondaryText2)
                                    
                                    Spacer()
                                    
                                    Text("보통")
                                        .font(.caption2)
                                        .foregroundColor(.whiffSecondaryText2)
                                    
                                    Spacer()
                                    
                                    Text("매우 좋아함")
                                        .font(.caption2)
                                        .foregroundColor(.whiffSecondaryText2)
                                }
                                .padding(.horizontal, 20)
                                
                                // 점수 인디케이터
                                HStack(spacing: 10) {
                                    ForEach(0...5, id: \.self) { score in
                                        Circle()
                                            .fill(noteRatings[currentNote] == score ? Color.whiffPrimary : Color.whiffSecondaryText2.opacity(0.3))
                                            .frame(width: 12, height: 12)
                                            .scaleEffect(noteRatings[currentNote] == score ? 1.3 : 1.0)
                                            .animation(.easeInOut(duration: 0.2), value: noteRatings[currentNote])
                                    }
                                }
                                
                                // 현재 점수 텍스트
                                if let currentRating = noteRatings[currentNote] {
                                    Text("\(currentRating)점")
                                        .font(.title3)
                                        .foregroundColor(.whiffPrimary)
                                        .bold()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                Spacer() // 하단 버튼을 아래로 밀기 위한 하나의 Spacer만 유지
                
                // 하단 버튼 영역
                VStack(spacing: 0) {
                    Divider()
                        .padding(.bottom, 20)
                    
                    HStack(spacing: 12) {
                        // 이전 버튼
                        if currentNoteIndex > 0 {
                            Button(action: {
                                currentNoteIndex -= 1
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("이전")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity)
                                .background(Color.whiffSectionBackground.opacity(0.2))
                                .foregroundColor(.whiffPrimaryText)
                                .cornerRadius(10)
                            }
                        }
                        
                        // 다음/완료 버튼
                        Button(action: {
                            if isLastNote {
                                // 평가 완료 - 상세 로그 출력
                                print("🎯 [노트 평가 완료]")
                                print("   📊 사용자 최종 평가:")
                                for (note, rating) in noteRatings.sorted(by: { $0.key < $1.key }) {
                                    let preference = rating >= 4 ? "👍 좋아함" : (rating <= 2 ? "👎 싫어함" : "😐 보통")
                                    print("      \(note): \(rating)점 (\(preference))")
                                }
                                
                                let highRated = noteRatings.filter { $0.value >= 4 }
                                let lowRated = noteRatings.filter { $0.value <= 2 }
                                let neutralRated = noteRatings.filter { $0.value == 3 }
                                
                                print("   📈 평가 요약:")
                                print("      좋아하는 노트: \(highRated.count)개")
                                print("      싫어하는 노트: \(lowRated.count)개")
                                print("      중립 노트: \(neutralRated.count)개")
                                
                                if neutralRated.count >= noteRatings.count / 2 {
                                    print("   ⚠️ 중립 평가가 많음 - 선호도가 명확하지 않을 수 있음")
                                } else {
                                    print("   ✅ 명확한 선호도 표현됨")
                                }
                                
                                onComplete(noteRatings)
                            } else {
                                // 다음 노트로
                                currentNoteIndex += 1
                            }
                        }) {
                            Text(isLastNote ? "평가 완료" : "다음")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity)
                                .background(canProceed ? Color.whiffPrimary : Color.whiffSecondaryText2.opacity(0.3))
                                .foregroundColor(.whiffWhiteText)
                                .cornerRadius(10)
                        }
                        .disabled(!canProceed)
                        .animation(.easeInOut(duration: 0.2), value: canProceed)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
            .navigationBarHidden(false)
            .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("향조 가이드") {
                    showScentGuide = true
                }
                .font(.subheadline)
                .foregroundColor(.whiffPrimary)
            }
        }
        .sheet(isPresented: $showScentGuide) {
            ScentGuideView(showScentGuide: $showScentGuide)
        }
        .onAppear {
            // 모든 노트를 중립(3점)으로 초기화하지 않고 선택하게 함
            noteRatings = Dictionary(uniqueKeysWithValues: extractedNotes.map { ($0, 3) })
            
            print("📝 [노트 평가 시작]")
            print("   - 평가할 노트: \(extractedNotes)")
            print("   - 총 \(extractedNotes.count)개 노트 평가 예정")
            print("   💡 사용자에게 명확한 선호도 표현을 유도해야 함")
        }
    }
    
    // 노트에 대한 간단한 설명 제공
    private func getNoteDescription(_ note: String) -> String {
        let descriptions: [String: String] = [
            "rose": "장미의 우아하고 로맨틱한 꽃 향",
            "jasmine": "자스민의 달콤하고 관능적인 꽃 향",
            "citrus": "상큼하고 생기 넘치는 감귤류 향",
            "bergamot": "얼그레이 차에서 느껴지는 시트러스 향",
            "vanilla": "따뜻하고 달콤한 바닐라 향",
            "sandalwood": "부드럽고 우디한 백단향",
            "musk": "깊고 관능적인 머스크 향",
            "amber": "따뜻하고 감성적인 앰버 향",
            "cedar": "깔끔하고 우디한 삼나무 향",
            "patchouli": "흙냄새가 나는 진한 우디 향",
            "lavender": "진정 효과가 있는 라벤더 향",
            "lemon": "신선하고 상큼한 레몬 향",
            "orange": "달콤하고 상큼한 오렌지 향",
            "mint": "시원하고 상쾌한 민트 향",
            "sage": "허브향이 진한 세이지 향"
        ]
        
        return descriptions[note.lowercased()] ?? "향수에서 자주 사용되는 향료입니다"
    }
}

// MARK: - Preview

struct NoteEvaluationView_Previews: PreviewProvider {
    static var previews: some View {
        NoteEvaluationView(
            extractedNotes: ["rose", "jasmine", "citrus", "vanilla", "sandalwood"],
            firstRecommendationData: FirstRecommendationResponse(recommendations: []),
            userPreferences: PerfumePreferences(),
            onComplete: { ratings in
                print("평가 완료: \(ratings)")
            }
        )
    }
}

// MARK: - 향조 가이드 컴포넌트들

private struct ScentGuideView: View {
    @Binding var showScentGuide: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text("향조 가이드")
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)
                    
                    ScentCategoryView()
                    ScentNoteView()
                    
                    Spacer()
                }
                .padding()
                .background(Color.whiffMainBackground)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        showScentGuide = false
                    }
                }
            }
        }
    }
}

private struct ScentCategoryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("향조 계열")
                .font(.headline)
                .foregroundColor(.whiffPrimaryText)
                .padding(.bottom, 4)
            
            Group {
                ScentCategoryItem(
                    title: "🌸 플로럴 (Floral)",
                    description: "부드럽고 여성스러운 꽃 향기. 봄에 어울리는 화사한 느낌.",
                    examples: "rose, jasmine, peony, lily, freesia, violet, magnolia, cherry blossom",
                    color: .pink
                )
                
                ScentCategoryItem(
                    title: "🌳 우디 (Woody)", 
                    description: "따뜻하고 고요한 나무 향. 고급스럽고 안정적인 인상을 줍니다.",
                    examples: "sandalwood, cedar, vetiver, patchouli, oak, pine, guaiac wood, cypress",
                    color: .brown
                )
                
                ScentCategoryItem(
                    title: "🍋 시트러스 (Citrus)",
                    description: "상쾌하고 활기찬 감귤류 향. 깔끔하고 에너지 넘치는 느낌.",
                    examples: "bergamot, lemon, orange, grapefruit, lime, yuzu, mandarin",
                    color: .orange
                )
                
                ScentCategoryItem(
                    title: "🌿 아로마틱 (Aromatic)",
                    description: "허브와 향신료의 신선하고 자극적인 향. 자연스럽고 깨끗한 느낌.",
                    examples: "lavender, rosemary, mint, thyme, sage, basil, eucalyptus",
                    color: .green
                )
                
                ScentCategoryItem(
                    title: "🍯 오리엔탈 (Oriental)",
                    description: "달콤하고 이국적인 향. 관능적이고 신비로운 분위기를 연출.",
                    examples: "vanilla, amber, musk, oud, frankincense, myrrh, benzoin",
                    color: .purple
                )
                
                ScentCategoryItem(
                    title: "🌊 프레시 (Fresh)",
                    description: "깨끗하고 시원한 바다와 물의 향. 청량감과 순수함을 표현.",
                    examples: "marine, water lily, cucumber, green tea, bamboo, ozone",
                    color: .whiffPrimary
                )
            }
        }
        .padding(.horizontal)
    }
}

private struct ScentCategoryItem: View {
    let title: String
    let description: String
    let examples: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(color)
            Text(description)
                .font(.body)
                .foregroundColor(.whiffSecondaryText2)
            Text("예시: \(examples)")
                .font(.caption)
                .foregroundColor(.whiffSecondaryText2)
        }
        .padding(.vertical, 8)
    }
}

private struct ScentNoteView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("주요 향조 설명")
                .font(.headline)
                .foregroundColor(.whiffPrimaryText)
                .padding(.bottom, 4)
            
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(scentNotes, id: \.name) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• \(note.name)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.whiffPrimaryText)
                        Text(note.description)
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                            .padding(.leading, 12)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private let scentNotes = [
        ScentNote(name: "Bergamot (베르가못)", description: "상큼하고 시트러스한 향으로 향수에 생기를 부여하며 톱노트에서 많이 사용됩니다."),
        ScentNote(name: "Rose (장미)", description: "클래식하고 우아한 꽃향기로 여성스럽고 로맨틱한 느낌을 줍니다."),
        ScentNote(name: "Jasmine (자스민)", description: "달콤하고 관능적인 꽃향기로 밤에 더욱 강하게 향을 발합니다."),
        ScentNote(name: "Sandalwood (샌달우드)", description: "크리미하고 따뜻한 나무향으로 베이스노트에서 깊이와 지속성을 제공합니다."),
        ScentNote(name: "Vanilla (바닐라)", description: "달콤하고 부드러운 향으로 편안함과 따뜻함을 주는 인기 노트입니다."),
        ScentNote(name: "Patchouli (패출리)", description: "흙냄새가 나는 독특한 향으로 보헤미안적이고 신비로운 분위기를 연출합니다."),
        ScentNote(name: "Musk (머스크)", description: "동물성 향으로 관능적이고 따뜻한 느낌을 주며 베이스노트로 많이 사용됩니다."),
        ScentNote(name: "Cedar (시더)", description: "건조하고 우디한 느낌으로 남성적이고 강인한 인상을 줍니다."),
        ScentNote(name: "Lavender (라벤더)", description: "진정 효과가 있는 허브향으로 편안하고 깨끗한 느낌을 줍니다."),
        ScentNote(name: "Amber (앰버)", description: "따뜻하고 달콤한 수지향으로 깊이와 복합성을 더해줍니다."),
        ScentNote(name: "Oud (우드)", description: "중동의 귀한 나무향으로 매우 강하고 독특한 향을 가집니다."),
        ScentNote(name: "Iris (아이리스)", description: "파우더리하고 우아한 꽃향기로 세련되고 고급스러운 느낌을 줍니다."),
        ScentNote(name: "Vetiver (베티버)", description: "뿌리에서 나는 흙내음과 풀냄새로 자연스럽고 신선한 느낌을 줍니다."),
        ScentNote(name: "Tonka Bean (통카빈)", description: "바닐라와 아몬드가 섞인 듯한 달콤한 향으로 따뜻함을 더해줍니다."),
        ScentNote(name: "Black Pepper (블랙페퍼)", description: "스파이시하고 따뜻한 향신료 향으로 활력과 에너지를 줍니다.")
    ]
}

private struct ScentNote {
    let name: String
    let description: String
} 
