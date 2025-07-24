import Foundation

class PerfumeDataUtils {
    
    // 실제적인 향수 데이터를 제공하는 함수
    static func createRealisticPerfumes() -> [Perfume] {
        return [
            Perfume(
                id: "chanel_no5",
                name: "No.5",
                brand: "Chanel",
                imageURL: "https://picsum.photos/200/300?random=1",
                price: 120000.0,
                description: "세계에서 가장 유명한 향수 중 하나로, 알데하이드 플로럴 향이 특징인 클래식한 향수입니다.",
                notes: PerfumeNotes(
                    top: ["알데하이드", "일랑일랑", "네롤리", "베르가못", "레몬"],
                    middle: ["로즈", "자스민", "릴리 오브 더 밸리", "아이리스"],
                    base: ["샌달우드", "머스크", "베티버", "바닐라", "앰버"]
                ),
                rating: 4.5,
                emotionTags: ["우아한", "클래식한", "여성스러운", "고급스러운"],
                similarity: 0.0
            ),
            Perfume(
                id: "tom_ford_black_orchid",
                name: "Black Orchid",
                brand: "Tom Ford",
                imageURL: "https://picsum.photos/200/300?random=2",
                price: 180000.0,
                description: "신비롭고 관능적인 매력을 지닌 럭셔리 향수로, 블랙 오키드의 독특한 향이 인상적입니다.",
                notes: PerfumeNotes(
                    top: ["블랙 트러플", "일랑일랑", "베르가못", "블랙 커런트"],
                    middle: ["블랙 오키드", "프루티 노트", "스파이시 노트"],
                    base: ["패출리", "바닐라", "인센스", "샌달우드"]
                ),
                rating: 4.3,
                emotionTags: ["신비로운", "관능적인", "럭셔리한", "독특한"],
                similarity: 0.0
            ),
            Perfume(
                id: "dior_sauvage",
                name: "Sauvage",
                brand: "Dior",
                imageURL: "https://picsum.photos/200/300?random=3",
                price: 140000.0,
                description: "남성적이고 야생적인 매력이 돋보이는 현대적인 향수로, 베르가못과 페퍼의 조화가 인상적입니다.",
                notes: PerfumeNotes(
                    top: ["칼라브리안 베르가못", "페퍼"],
                    middle: ["시추안 페퍼", "라벤더", "핑크 페퍼", "베티버", "패출리", "제라늄"],
                    base: ["앰버그리스", "시더", "라브다넘"]
                ),
                rating: 4.4,
                emotionTags: ["남성적인", "야생적인", "현대적인", "신선한"],
                similarity: 0.0
            ),
            Perfume(
                id: "jo_malone_peony_blush_suede",
                name: "Peony & Blush Suede",
                brand: "Jo Malone London",
                imageURL: "https://picsum.photos/200/300?random=4",
                price: 95000.0,
                description: "피오니의 로맨틱한 향과 스웨이드의 부드러운 감촉이 어우러진 섬세하고 우아한 향수입니다.",
                notes: PerfumeNotes(
                    top: ["레드 애플"],
                    middle: ["피오니", "로즈"],
                    base: ["스웨이드"]
                ),
                rating: 4.2,
                emotionTags: ["로맨틱한", "우아한", "섬세한", "부드러운"],
                similarity: 0.0
            ),
            Perfume(
                id: "byredo_gypsy_water",
                name: "Gypsy Water",
                brand: "Byredo",
                imageURL: "https://picsum.photos/200/300?random=5",
                price: 160000.0,
                description: "자유롭고 신비로운 영혼을 표현한 향수로, 파인 니들과 인센스의 독특한 조합이 매력적입니다.",
                notes: PerfumeNotes(
                    top: ["베르가못", "레몬", "페퍼", "주니퍼 베리"],
                    middle: ["인센스", "파인 니들", "오르리스"],
                    base: ["바닐라", "샌달우드", "앰버"]
                ),
                rating: 4.1,
                emotionTags: ["자유로운", "신비로운", "독특한", "모던한"],
                similarity: 0.0
            ),
            Perfume(
                id: "le_labo_santal_33",
                name: "Santal 33",
                brand: "Le Labo",
                imageURL: "https://picsum.photos/200/300?random=6",
                price: 200000.0,
                description: "독특한 샌달우드 향이 특징인 유니섹스 향수로, 스모키하고 크리미한 향이 인상적입니다.",
                notes: PerfumeNotes(
                    top: ["바이올렛", "카다멈", "스파이시 노트"],
                    middle: ["아이리스", "앰브레트 시드", "아미리스"],
                    base: ["샌달우드", "시더", "가죽", "머스크"]
                ),
                rating: 4.0,
                emotionTags: ["유니섹스", "스모키한", "크리미한", "독특한"],
                similarity: 0.0
            ),
            Perfume(
                id: "maison_margiela_replica_by_the_fireplace",
                name: "REPLICA By the Fireplace",
                brand: "Maison Margiela",
                imageURL: "https://picsum.photos/200/300?random=7",
                price: 130000.0,
                description: "따뜻한 벽난로 옆의 아늑한 분위기를 담은 향수로, 체스넛과 바닐라의 포근한 향이 특징입니다.",
                notes: PerfumeNotes(
                    top: ["핑크 페퍼", "오렌지 블라썸", "클로브 오일"],
                    middle: ["체스넛", "구아이악 우드", "카시미어 우드"],
                    base: ["바닐라", "머스크"]
                ),
                rating: 4.3,
                emotionTags: ["따뜻한", "아늑한", "포근한", "겨울적인"],
                similarity: 0.0
            ),
            Perfume(
                id: "versace_bright_crystal",
                name: "Bright Crystal",
                brand: "Versace",
                imageURL: "https://picsum.photos/200/300?random=8",
                price: 85000.0,
                description: "밝고 화사한 플로럴 향수로, 석류와 피오니의 조화가 아름다운 여성스러운 향수입니다.",
                notes: PerfumeNotes(
                    top: ["석류", "유즈", "워터 노트"],
                    middle: ["피오니", "목련", "연꽃"],
                    base: ["앰버", "머스크", "마호가니"]
                ),
                rating: 4.2,
                emotionTags: ["밝은", "화사한", "여성스러운", "상쾌한"],
                similarity: 0.0
            ),
            Perfume(
                id: "hermes_terre_dhermes",
                name: "Terre d'Hermès",
                brand: "Hermès",
                imageURL: "https://picsum.photos/200/300?random=9",
                price: 165000.0,
                description: "대지의 향을 담은 우디 시트러스 향수로, 오렌지와 플린트의 독특한 조합이 매력적입니다.",
                notes: PerfumeNotes(
                    top: ["오렌지", "그레이프프루트"],
                    middle: ["플린트", "제라늄", "베이 로즈"],
                    base: ["시더", "베티버", "벤조인"]
                ),
                rating: 4.4,
                emotionTags: ["자연스러운", "남성적인", "우디", "세련된"],
                similarity: 0.0
            ),
            Perfume(
                id: "bulgari_omnia_coral",
                name: "Omnia Coral",
                brand: "Bulgari",
                imageURL: "https://picsum.photos/200/300?random=10",
                price: 75000.0,
                description: "산호빛처럼 화사하고 트로피컬한 향수로, 히비스커스와 석류의 조화가 인상적입니다.",
                notes: PerfumeNotes(
                    top: ["베르가못", "구아바"],
                    middle: ["히비스커스", "워터 릴리"],
                    base: ["시더우드", "머스크"]
                ),
                rating: 4.1,
                emotionTags: ["트로피컬", "화사한", "상큼한", "여름적인"],
                similarity: 0.0
            )
        ]
    }
    
    // 간단한 샘플 데이터 (기존 코드 호환성용)
    static func createSamplePerfumes() -> [Perfume] {
        let realisticPerfumes = createRealisticPerfumes()
        return Array(realisticPerfumes.prefix(3)) // 처음 3개만 반환
    }
} 