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
                            Text(getNoteDisplayName(currentNote))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.whiffPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
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
    
    // 노트에 대한 상세한 설명 제공 (완전한 버전)
    private func getNoteDescription(_ note: String) -> String {
        let descriptions: [String: String] = [
            // 기본 노트들
            "rose": "우아하고 로맨틱한 장미의 꽃 향",
            "jasmine": "달콤하고 관능적인 자스민의 꽃 향",
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
            "sage": "허브향이 진한 세이지 향",
            "oud": "중동의 귀한 나무향으로 매우 강하고 독특한 향",
            "iris": "파우더리하고 우아한 꽃향기",
            "vetiver": "뿌리에서 나는 흙내음과 풀냄새",
            "tonka bean": "바닐라와 아몬드가 섞인 듯한 달콤한 향",
            "black pepper": "스파이시하고 따뜻한 향신료 향",
            
            // 추가 누락된 노트들
            "leather": "고급스럽고 부드러운 가죽 향",
            "benzoin": "따뜻하고 달콤한 바닐라 계열 수지향",
            "cardamom": "스파이시하고 시원한 카다몸 향신료 향",
            "ginger": "따뜻하고 알싸한 생강 향신료 향",
            "cinnamon": "달콤하고 따뜻한 계피 향신료 향",
            "labdanum": "깊고 따뜻한 앰버 계열의 수지향",
            "cashmeran": "부드럽고 포근한 캐시미어 같은 머스크 향",
            "galbanum": "그린하고 허브 같은 갈바넘 향",
            
            // 시트러스 계열
            "grapefruit": "상쾌하고 쌉싸름한 자몽 향",
            "lime": "신선하고 짜릿한 라임 향",
            "yuzu": "일본의 상큼한 유자 향",
            "mandarin": "달콤하고 부드러운 만다린 향",
            "tangerine": "달콤하고 따뜻한 귤 향",
            "neroli": "우아하고 플로럴한 네롤리 향",
            "petitgrain": "그린하고 우디한 페티그레인 향",
            
            // 플로럴 계열
            "peony": "부드럽고 로맨틱한 피오니 향",
            "lily": "순수하고 우아한 릴리 향",
            "freesia": "가볍고 상쾌한 프리지아 향",
            "violet": "파우더리하고 달콤한 바이올렛 향",
            "magnolia": "크리미하고 우아한 목련 향",
            "cherry blossom": "부드럽고 봄다운 벚꽃 향",
            "gardenia": "진하고 크리미한 가드니아 향",
            "tuberose": "강렬하고 관능적인 튜베로즈 향",
            "ylang ylang": "이국적이고 달콤한 일랑일랑 향",
            "lily of the valley": "깨끗하고 순수한 은방울꽃 향",
            
            // 우디 계열
            "oak": "강인하고 견고한 오크 향",
            "pine": "상쾌하고 숲의 파인 향",
            "guaiac wood": "스모키하고 독특한 구아이악 우드 향",
            "cypress": "그린하고 상쾌한 사이프러스 향",
            "birch": "깨끗하고 시원한 자작나무 향",
            "ebony": "깊고 고급스러운 흑단 향",
            "rosewood": "부드럽고 플로럴한 로즈우드 향",
            "agarwood": "고급스럽고 신비로운 침향",
            
            // 허브/아로마틱 계열
            "rosemary": "상쾌하고 허브 같은 로즈마리 향",
            "thyme": "따뜻하고 허브 같은 타임 향",
            "basil": "신선하고 그린한 바질 향",
            "eucalyptus": "시원하고 약용 같은 유칼립투스 향",
            "oregano": "따뜻하고 허브 같은 오레가노 향",
            "clary sage": "허브 같고 그린한 클라리 세이지 향",
            "juniper": "상쾌하고 진한 주니퍼 향",
            "bay leaves": "따뜻하고 허브 같은 월계수 향",
            
            // 오리엔탈/수지 계열
            "frankincense": "신성하고 신비로운 프랑킨센스 향",
            "myrrh": "깊고 신비로운 몰약 향",
            "olibanum": "종교적이고 신성한 올리바넘 향",
            "elemi": "상쾌하고 수지 같은 엘레미 향",
            "copal": "따뜻하고 수지 같은 코팔 향",
            
            // 향신료 계열
            "clove": "따뜻하고 스파이시한 정향 향",
            "nutmeg": "따뜻하고 달콤한 육두구 향",
            "allspice": "복합적이고 따뜻한 올스파이스 향",
            "star anise": "달콤하고 리코리스 같은 팔각 향",
            "coriander": "상쾌하고 스파이시한 고수 향",
            "cumin": "따뜻하고 흙 같은 커민 향",
            "pink pepper": "부드럽고 스파이시한 핑크페퍼 향",
            "white pepper": "깔끔하고 스파이시한 화이트페퍼 향",
            
            // 프레시/아쿠아틱 계열
            "marine": "깨끗하고 바다 같은 마린 향",
            "water lily": "순수하고 아쿠아틱한 수련 향",
            "cucumber": "시원하고 신선한 오이 향",
            "green tea": "깔끔하고 차분한 녹차 향",
            "bamboo": "그린하고 자연스러운 대나무 향",
            "ozone": "깨끗하고 공기 같은 오존 향",
            "rain": "상쾌하고 깨끗한 빗물 향",
            "sea salt": "짭짤하고 바다 같은 소금 향",
            
            // 과일 계열
            "apple": "상큼하고 달콤한 사과 향",
            "pear": "달콤하고 부드러운 배 향",
            "peach": "달콤하고 벨벳 같은 복숭아 향",
            "apricot": "달콤하고 부드러운 살구 향",
            "plum": "달콤하고 진한 자두 향",
            "fig": "달콤하고 그린한 무화과 향",
            "coconut": "크리미하고 트로피컬한 코코넛 향",
            "pineapple": "달콤하고 트로피컬한 파인애플 향",
            "blackcurrant": "달콤하고 진한 블랙커런트 향",
            "raspberry": "달콤하고 상큼한 라즈베리 향",
            "strawberry": "달콤하고 사랑스러운 딸기 향",
            
            // 견과류/단맛 계열
            "almond": "달콤하고 견과류 같은 아몬드 향",
            "hazelnut": "고소하고 달콤한 헤이즐넛 향",
            "pistachio": "고소하고 버터 같은 피스타치오 향",
            "walnut": "고소하고 진한 호두 향",
            "honey": "달콤하고 따뜻한 꿀 향",
            "caramel": "달콤하고 버터 같은 카라멜 향",
            "chocolate": "진하고 달콤한 초콜릿 향",
            "coffee": "쓰면서 향긋한 커피 향",
            
            // 동물성/머스크 계열
            "ambergris": "깊고 해양적인 앰버그리스 향",
            "civet": "강렬하고 동물적인 시벳 향",
            "castoreum": "따뜻하고 동물적인 카스토레움 향",
            "white musk": "깨끗하고 부드러운 화이트 머스크 향",
            "red musk": "따뜻하고 관능적인 레드 머스크 향",
            
            // 기타 특수 노트들
            "aldehydes": "반짝이고 비누 같은 알데하이드 향",
            "iso e super": "우디하고 벨벳 같은 이소 이 수퍼 향",
            "ambroxan": "깨끗하고 앰버 같은 암브록산 향",
            "hedione": "투명하고 재스민 같은 헤디온 향",
            "lilial": "부드럽고 플로럴한 릴리알 향",
            "calone": "아쿠아틱하고 멜론 같은 칼론 향",
            "dihydromyrcenol": "시트러스하고 상쾌한 디하이드로미르세놀 향",
            
            // 담배/스모키 계열
            "tobacco": "따뜻하고 스모키한 담배 향",
            "pipe tobacco": "달콤하고 스모키한 파이프 담배 향",
            "birch tar": "스모키하고 타르 같은 자작나무 타르 향",
            "incense": "신비롭고 영적인 인센스 향",
            "smoke": "스모키하고 드라이한 연기 향",
            
            // 허브/그린 계열
            "grass": "신선하고 그린한 풀 향",
            "green leaves": "상쾌하고 자연스러운 푸른 잎 향",
            "moss": "축축하고 자연스러운 이끼 향",
            "fern": "그린하고 자연스러운 고사리 향",
            "tomato leaf": "그린하고 채소 같은 토마토 잎 향",
            "rhubarb": "신맛이 나고 그린한 대황 향",
            
            // 미네랄/메탈릭 계열
            "mineral": "깨끗하고 차가운 미네랄 향",
            "metallic": "차갑고 금속적인 메탈릭 향",
            "salt": "짭짤하고 바다 같은 소금 향",
            "stone": "차갑고 미네랄한 돌 향",
            "concrete": "모던하고 도시적인 콘크리트 향"
        ]
        
        return descriptions[note.lowercased()] ?? "독특하고 매력적인 향료"
    }
    // 영문명과 한국어명을 함께 반환하는 함수 (완전한 버전)
    private func getNoteDisplayName(_ note: String) -> String {
        let noteTranslations: [String: String] = [
            // 기본 노트들
            "rose": "Rose\n(장미)",
            "jasmine": "Jasmine\n(자스민)",
            "citrus": "Citrus\n(시트러스)",
            "bergamot": "Bergamot\n(베르가못)",
            "vanilla": "Vanilla\n(바닐라)",
            "sandalwood": "Sandalwood\n(샌달우드)",
            "musk": "Musk\n(머스크)",
            "amber": "Amber\n(앰버)",
            "cedar": "Cedar\n(시더)",
            "patchouli": "Patchouli\n(패출리)",
            "lavender": "Lavender\n(라벤더)",
            "lemon": "Lemon\n(레몬)",
            "orange": "Orange\n(오렌지)",
            "mint": "Mint\n(민트)",
            "sage": "Sage\n(세이지)",
            "oud": "Oud\n(우드)",
            "iris": "Iris\n(아이리스)",
            "vetiver": "Vetiver\n(베티버)",
            "tonka bean": "Tonka Bean\n(통카빈)",
            "black pepper": "Black Pepper\n(블랙페퍼)",
            
            // 추가 누락된 노트들
            "leather": "Leather\n(가죽)",
            "benzoin": "Benzoin\n(벤조인)",
            "cardamom": "Cardamom\n(카다몸)",
            "ginger": "Ginger\n(생강)",
            "cinnamon": "Cinnamon\n(계피)",
            "labdanum": "Labdanum\n(라브다넘)",
            "cashmeran": "Cashmeran\n(캐시미란)",
            "galbanum": "Galbanum\n(갈바넘)",
            
            // 시트러스 계열
            "grapefruit": "Grapefruit\n(자몽)",
            "lime": "Lime\n(라임)",
            "yuzu": "Yuzu\n(유자)",
            "mandarin": "Mandarin\n(만다린)",
            "tangerine": "Tangerine\n(귤)",
            "neroli": "Neroli\n(네롤리)",
            "petitgrain": "Petitgrain\n(페티그레인)",
            
            // 플로럴 계열
            "peony": "Peony\n(피오니)",
            "lily": "Lily\n(릴리)",
            "freesia": "Freesia\n(프리지아)",
            "violet": "Violet\n(바이올렛)",
            "magnolia": "Magnolia\n(목련)",
            "cherry blossom": "Cherry Blossom\n(벚꽃)",
            "gardenia": "Gardenia\n(가드니아)",
            "tuberose": "Tuberose\n(튜베로즈)",
            "ylang ylang": "Ylang Ylang\n(일랑일랑)",
            "lily of the valley": "Lily of the Valley\n(은방울꽃)",
            
            // 우디 계열
            "oak": "Oak\n(오크)",
            "pine": "Pine\n(파인)",
            "guaiac wood": "Guaiac Wood\n(구아이악 우드)",
            "cypress": "Cypress\n(사이프러스)",
            "birch": "Birch\n(자작나무)",
            "ebony": "Ebony\n(흑단)",
            "rosewood": "Rosewood\n(로즈우드)",
            "agarwood": "Agarwood\n(침향)",
            
            // 허브/아로마틱 계열
            "rosemary": "Rosemary\n(로즈마리)",
            "thyme": "Thyme\n(타임)",
            "basil": "Basil\n(바질)",
            "eucalyptus": "Eucalyptus\n(유칼립투스)",
            "oregano": "Oregano\n(오레가노)",
            "clary sage": "Clary Sage\n(클라리 세이지)",
            "juniper": "Juniper\n(주니퍼)",
            "bay leaves": "Bay Leaves\n(월계수)",
            
            // 오리엔탈/수지 계열
            "frankincense": "Frankincense\n(프랑킨센스)",
            "myrrh": "Myrrh\n(몰약)",
            "olibanum": "Olibanum\n(올리바넘)",
            "elemi": "Elemi\n(엘레미)",
            "copal": "Copal\n(코팔)",
            
            // 향신료 계열
            "clove": "Clove\n(정향)",
            "nutmeg": "Nutmeg\n(육두구)",
            "allspice": "Allspice\n(올스파이스)",
            "star anise": "Star Anise\n(팔각)",
            "coriander": "Coriander\n(고수)",
            "cumin": "Cumin\n(커민)",
            "pink pepper": "Pink Pepper\n(핑크페퍼)",
            "white pepper": "White Pepper\n(화이트페퍼)",
            
            // 프레시/아쿠아틱 계열
            "marine": "Marine\n(마린)",
            "water lily": "Water Lily\n(수련)",
            "cucumber": "Cucumber\n(오이)",
            "green tea": "Green Tea\n(녹차)",
            "bamboo": "Bamboo\n(대나무)",
            "ozone": "Ozone\n(오존)",
            "rain": "Rain\n(빗물)",
            "sea salt": "Sea Salt\n(바다소금)",
            
            // 과일 계열
            "apple": "Apple\n(사과)",
            "pear": "Pear\n(배)",
            "peach": "Peach\n(복숭아)",
            "apricot": "Apricot\n(살구)",
            "plum": "Plum\n(자두)",
            "fig": "Fig\n(무화과)",
            "coconut": "Coconut\n(코코넛)",
            "pineapple": "Pineapple\n(파인애플)",
            "blackcurrant": "Blackcurrant\n(블랙커런트)",
            "raspberry": "Raspberry\n(라즈베리)",
            "strawberry": "Strawberry\n(딸기)",
            
            // 견과류/단맛 계열
            "almond": "Almond\n(아몬드)",
            "hazelnut": "Hazelnut\n(헤이즐넛)",
            "pistachio": "Pistachio\n(피스타치오)",
            "walnut": "Walnut\n(호두)",
            "honey": "Honey\n(꿀)",
            "caramel": "Caramel\n(카라멜)",
            "chocolate": "Chocolate\n(초콜릿)",
            "coffee": "Coffee\n(커피)",
            
            // 동물성/머스크 계열
            "ambergris": "Ambergris\n(앰버그리스)",
            "civet": "Civet\n(시벳)",
            "castoreum": "Castoreum\n(카스토레움)",
            "white musk": "White Musk\n(화이트 머스크)",
            "red musk": "Red Musk\n(레드 머스크)",
            
            // 기타 특수 노트들
            "aldehydes": "Aldehydes\n(알데하이드)",
            "iso e super": "Iso E Super\n(이소 이 수퍼)",
            "ambroxan": "Ambroxan\n(암브록산)",
            "hedione": "Hedione\n(헤디온)",
            "lilial": "Lilial\n(릴리알)",
            "calone": "Calone\n(칼론)",
            "dihydromyrcenol": "Dihydromyrcenol\n(디하이드로미르세놀)",
            
            // 담배/스모키 계열
            "tobacco": "Tobacco\n(담배)",
            "pipe tobacco": "Pipe Tobacco\n(파이프 담배)",
            "birch tar": "Birch Tar\n(자작나무 타르)",
            "incense": "Incense\n(인센스)",
            "smoke": "Smoke\n(연기)",
            
            // 허브/그린 계열
            "grass": "Grass\n(풀)",
            "green leaves": "Green Leaves\n(푸른 잎)",
            "moss": "Moss\n(이끼)",
            "fern": "Fern\n(고사리)",
            "tomato leaf": "Tomato Leaf\n(토마토 잎)",
            "rhubarb": "Rhubarb\n(대황)",
            
            // 미네랄/메탈릭 계열
            "mineral": "Mineral\n(미네랄)",
            "metallic": "Metallic\n(메탈릭)",
            "salt": "Salt\n(소금)",
            "stone": "Stone\n(돌)",
            "concrete": "Concrete\n(콘크리트)"
        ]
        
        return noteTranslations[note.lowercased()] ?? "\(note.capitalized)\n(\(note.lowercased()))"
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
