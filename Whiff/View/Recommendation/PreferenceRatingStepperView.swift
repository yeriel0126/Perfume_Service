import SwiftUI

struct PreferenceRatingStepperView: View {
    let projectName: String
    let perfumes: [Perfume]
    let projectId: UUID
    let firstRecommendationData: FirstRecommendationResponse?
    let userPreferences: PerfumePreferences?
    
    @State private var currentIndex: Int = 0
    @State private var ratings: [String: Int] = [:]
    @State private var navigateToFinal = false
    @State private var showScentGuide = false
    @State private var isLoading = false
    @State private var error: Error?
    @EnvironmentObject var projectStore: ProjectStore

    let emojiMap: [Int: String] = [
        0: "😣", 1: "😖", 2: "😕", 3: "😐", 4: "🙂", 5: "😄"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // 진행률 표시 (상단에 충분한 공간 확보)
            VStack(spacing: 8) {
                ProgressView(value: Double(currentIndex), total: Double(perfumes.count))
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                
                Text("\(currentIndex + 1) / \(perfumes.count)")
                    .font(.caption)
                    .foregroundColor(.whiffSecondaryText2)
            }
            .padding(.top, 10)
            
            if currentIndex < perfumes.count {
                // 현재 향수 평가
                VStack(spacing: 24) {
                    // 향수 카드
                    RecommendationCardView(
                        perfume: perfumes[currentIndex], 
                        matchScore: 85 + (currentIndex * 3) // 고정된 매치 점수
                    )
                    .id("perfume-\(currentIndex)") // 인덱스가 바뀔 때마다 카드 재생성
                    
                    // 평가 섹션
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("이 향수는 어떤가요?")
                                .font(.title3)
                                .bold()
                                .multilineTextAlignment(.center)
                            
                            Text("아래 향조 구성을 참고하여\n이 향수에 대한 선호도를 평가해주세요")
                                .font(.subheadline)
                                .foregroundColor(.whiffSecondaryText2)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // 이모지 선택
                        HStack(spacing: 12) {
                            ForEach(0...5, id: \.self) { value in
                                Button(action: {
                                    // 향수 ID를 직접 키로 사용
                                    let perfumeId = perfumes[currentIndex].id
                                    ratings[perfumeId] = value
                                    print("✅ [선호도 평가] \(perfumes[currentIndex].name): \(value)점 평가")
                                }) {
                                    Text(emojiMap[value]!)
                                        .font(.system(size: 40))
                                        .opacity(isSelected(value) ? 1.0 : 0.6)
                                        .scaleEffect(isSelected(value) ? 1.2 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: isSelected(value))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .frame(width: 50, height: 50)
                                .contentShape(Rectangle())
                            }
                        }
                        .padding(.horizontal)
                        
                        // 이전/다음 버튼
                        HStack(spacing: 12) {
                            // 이전 버튼
                            if currentIndex > 0 {
                                Button(action: {
                                    previousPerfume()
                                }) {
                                    Text("이전")
                                        .bold()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.whiffSecondaryText2.opacity(0.6))
                                        .foregroundColor(.whiffWhiteText)
                                        .cornerRadius(10)
                                }
                            }
                            
                            // 다음 버튼
                            Button(action: {
                                nextPerfume()
                            }) {
                                Text(currentIndex == perfumes.count - 1 ? "완료" : "다음")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isCurrentPerfumeRated() ? Color.whiffPrimary : Color.whiffSecondaryText2.opacity(0.3))
                                    .foregroundColor(.whiffWhiteText)
                                    .cornerRadius(10)
                            }
                            .disabled(!isCurrentPerfumeRated())
                        }
                        .padding(.horizontal)
                        .background(Color.whiffMainBackground)
                    }
                }
            } else {
                // 완료 화면
                VStack(spacing: 32) {
                    Text("모든 향수를 평가했어요!")
                        .font(.headline)
                    
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("분석 중...")
                                .font(.subheadline)
                                .foregroundColor(.whiffSecondaryText2)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Button("최종 추천 보기") {
                                Task {
                                    await submitRatings()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            // 이전 버튼 (마지막 향수로 돌아가기)
                            Button("마지막 향수 다시 평가하기") {
                                previousPerfume()
                            }
                            .foregroundColor(.whiffSecondaryText2)
                            .font(.subheadline)
                        }
                    }
                    
                    if let error = error {
                        Text("오류: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.whiffMainBackground)
        .navigationTitle("선호도 평가")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showScentGuide = true }) {
                    Text("현재 향수 노트")
                }
            }
        }
        .navigationDestination(isPresented: $navigateToFinal) {
            FinalRecommendationView(
                projectName: projectName,
                firstRecommendationData: firstRecommendationData,
                userPreferences: userPreferences
            )
            .environmentObject(projectStore)
        }
        .sheet(isPresented: $showScentGuide) {
            CurrentPerfumeNotesView(
                perfume: currentIndex < perfumes.count ? perfumes[currentIndex] : nil,
                showScentGuide: $showScentGuide
            )
        }
    }
    
    private func isSelected(_ value: Int) -> Bool {
        let perfumeId = perfumes[currentIndex].id
        return ratings[perfumeId] == value
    }
    
    private func isCurrentPerfumeRated() -> Bool {
        let perfumeId = perfumes[currentIndex].id
        return ratings[perfumeId] != nil
    }
    
    private func nextPerfume() {
        if currentIndex < perfumes.count - 1 {
            currentIndex += 1
            // 다음 향수의 노트 정보 확인
            if currentIndex < perfumes.count {
                let nextPerfume = perfumes[currentIndex]
                print("🔄 [향수 변경] \(currentIndex + 1)/\(perfumes.count): \(nextPerfume.name)")
                print("   - Top notes: \(nextPerfume.notes.top)")
                print("   - Middle notes: \(nextPerfume.notes.middle)")
                print("   - Base notes: \(nextPerfume.notes.base)")
            }
        } else {
            // 마지막 향수면 제출
            Task {
                await submitRatings()
            }
        }
    }
    
    private func previousPerfume() {
        if currentIndex > 0 {
            currentIndex -= 1
            // 이전 향수의 노트 정보 확인
            if currentIndex >= 0 {
                let previousPerfume = perfumes[currentIndex]
                print("🔄 [향수 변경] \(currentIndex + 1)/\(perfumes.count): \(previousPerfume.name)")
                print("   - Top notes: \(previousPerfume.notes.top)")
                print("   - Middle notes: \(previousPerfume.notes.middle)")
                print("   - Base notes: \(previousPerfume.notes.base)")
            }
        }
    }
    
    private func submitRatings() async {
        isLoading = true
        error = nil
        
        do {
            print("🎯 [선호도 평가 상세 분석]")
            print("   - 사용자가 평가한 향수 수: \(ratings.count)개")
            print("   - 전체 향수 수: \(perfumes.count)개")
            
            // 실제 평가한 향수들 출력
            print("   📋 사용자 평가 내역:")
            for (perfumeId, rating) in ratings.sorted(by: { $0.key < $1.key }) {
                if let perfume = perfumes.first(where: { $0.id == perfumeId }) {
                    print("      \(perfume.name): \(rating)점")
                } else {
                    print("      [알 수 없는 향수 ID: \(perfumeId)]: \(rating)점")
                }
            }
            
            // String 키를 UUID로 변환
            var uuidRatings: [UUID: Int] = [:]
            var conversionIssues: [String] = []
            
            for (stringId, rating) in ratings {
                if let uuid = UUID(uuidString: stringId) {
                    uuidRatings[uuid] = rating
                } else {
                    // UUID 변환 실패 시 새 UUID 생성
                    let newUUID = UUID()
                    uuidRatings[newUUID] = rating
                    conversionIssues.append("'\(stringId)' -> \(newUUID)")
                    #if DEBUG
                    print("🔧 [UUID 자동생성] \(stringId) -> \(newUUID)")
                    #endif
                }
            }
            
            if !conversionIssues.isEmpty {
                print("⚠️ [UUID 변환 문제] \(conversionIssues.count)개 향수 ID 변환 실패:")
                for issue in conversionIssues {
                    print("      \(issue)")
                }
            }
            
            print("   🔧 변환 후 UUID 평가 수: \(uuidRatings.count)개")
            
            if ratings.count != uuidRatings.count {
                print("🚨 [데이터 불일치] 원본(\(ratings.count))과 변환 후(\(uuidRatings.count)) 개수가 다름!")
            }
            
            try await projectStore.submitPreferenceRatings(projectId: projectId, ratings: uuidRatings)
            navigateToFinal = true
            print("✅ [선호도 평가] 실제 \(ratings.count)개 평가 → \(uuidRatings.count)개 시스템 처리 완료")
        } catch {
            self.error = error
            print("❌ [선호도 평가] 제출 실패: \(error)")
        }
        
        isLoading = false
    }
    
    private func convertToUUIDRatings() -> [UUID: Int] {
        var uuidRatings: [UUID: Int] = [:]
        for (stringId, rating) in ratings {
            if let uuid = UUID(uuidString: stringId) {
                uuidRatings[uuid] = rating
            } else {
                // UUID 변환 실패 시 새 UUID 생성
                let newUUID = UUID()
                uuidRatings[newUUID] = rating
                #if DEBUG
                print("🔧 [UUID 자동생성] \(stringId) -> \(newUUID)")
                #endif
            }
        }
        return uuidRatings
    }
}

private struct CurrentPerfumeNotesView: View {
    let perfume: Perfume?
    @Binding var showScentGuide: Bool
    @State private var showGeneralGuide = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더
                VStack(alignment: .center, spacing: 8) {
                    Text("현재 향수 노트")
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    if let perfume = perfume {
                        VStack(spacing: 4) {
                            Text(perfume.name)
                                .font(.headline)
                                .foregroundColor(.whiffPrimaryText)
                            Text(perfume.brand)
                                .font(.subheadline)
                                .foregroundColor(.whiffSecondaryText2)
                        }
                    }
                }
                .padding(.bottom, 8)
                
                if let perfume = perfume {
                    // 현재 향수의 실제 노트 정보
                    VStack(alignment: .leading, spacing: 20) {
                        Text("이 향수의 향조 구성")
                            .font(.headline)
                            .foregroundColor(.whiffPrimaryText)
                        
                        if !perfume.notes.top.isEmpty {
                            NoteDetailSection(
                                title: "🌟 탑 노트 (Top Notes)",
                                subtitle: "첫 번째로 느껴지는 향, 5-15분 지속",
                                notes: perfume.notes.top,
                                color: .green
                            )
                        }
                        
                        if !perfume.notes.middle.isEmpty {
                            NoteDetailSection(
                                title: "💫 미들 노트 (Middle Notes)",
                                subtitle: "향수의 중심이 되는 향, 2-4시간 지속",
                                notes: perfume.notes.middle,
                                color: .orange
                            )
                        }
                        
                        if !perfume.notes.base.isEmpty {
                            NoteDetailSection(
                                title: "🌙 베이스 노트 (Base Notes)",
                                subtitle: "가장 오래 지속되는 향, 4-8시간 지속",
                                notes: perfume.notes.base,
                                color: .purple
                            )
                        }
                        
                        // 감정 태그
                        if !perfume.emotionTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("✨ 향수 특징")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.whiffPrimaryText)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(perfume.emotionTags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.whiffPrimary.opacity(0.1))
                                            .foregroundColor(.whiffPrimary)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.whiffSecondaryText2)
                        Text("향수 정보를 불러올 수 없습니다")
                            .font(.subheadline)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.whiffMainBackground)
                }
                
                // 일반 향조 가이드 버튼
                Button(action: {
                    showGeneralGuide = true
                }) {
                    HStack {
                        Image(systemName: "book.circle")
                        Text("일반 향조 가이드 보기")
                    }
                    .font(.subheadline)
                    .foregroundColor(.whiffPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.whiffPrimary.opacity(0.1))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                
                Spacer()
                
                // 닫기 버튼
                Button(action: {
                    showScentGuide = false
                }) {
                    Text("닫기")
                        .bold()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.whiffPrimary)
                        .foregroundColor(.whiffWhiteText)
                        .cornerRadius(10)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            }
            .padding()
            .background(Color.whiffMainBackground)
        }
        .sheet(isPresented: $showGeneralGuide) {
            ScentGuideView(showScentGuide: $showGeneralGuide)
        }
    }
}

private struct NoteDetailSection: View {
    let title: String
    let subtitle: String
    let notes: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.whiffSecondaryText2)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(notes, id: \.self) { note in
                    Text(note)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.1))
                        .foregroundColor(color)
                        .cornerRadius(12)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
}

private struct ScentGuideView: View {
    @Binding var showScentGuide: Bool
    
    var body: some View {
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
                
                Button(action: {
                    showScentGuide = false
                }) {
                    Text("닫기")
                        .bold()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.whiffPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            }
            .padding()
            .background(Color.whiffMainBackground)
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
                    color: .blue
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

