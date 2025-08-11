import SwiftUI

// MARK: - Whiff 색상 시스템
extension Color {
    
    // MARK: - Gradient Colors
    static let whiffGradientStart = Color(hex: "F5F8D1")  // 연한 노란-녹색
    static let whiffGradientEnd = Color(hex: "1DCBB1")    // 터키석
    
    // 메인 그라데이션 (위에서 아래로)
    static let whiffMainGradient = LinearGradient(
        colors: [Color.whiffGradientStart, Color.whiffGradientEnd],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Text Colors
    static let whiffLogo = Color(hex: "334651")          // Whiff 로고색 (다크 그레이-블루)
    static let whiffPrimaryText = Color(hex: "000000")   // 메인 텍스트 (검정)
    static let whiffSecondaryText1 = Color(hex: "334651") // 보조 텍스트 1 (로고색과 동일)
    static let whiffSecondaryText2 = Color(hex: "919191") // 보조 텍스트 2 (회색)
    static let whiffWhiteText = Color(hex: "FFFFFF")     // 흰색 텍스트
    
    // MARK: - Background Colors
    static let whiffMainBackground = Color(hex: "FFFFFF")  // 메인 배경 (흰색)
    static let whiffNextCard = Color(hex: "334651")        // 다음 버튼/카드 (다크 그레이-블루)
    static let whiffSectionBackground = Color(hex: "F2F2F2") // 섹션 배경 (연한 회색)
    
    // MARK: - 편의 별칭 (기존 코드와의 호환성)
    static let whiffPrimary = whiffGradientEnd           // 메인 컬러 (터키석)
    static let whiffDark = whiffNextCard                 // 다크 컬러
    static let whiffLight = whiffSectionBackground       // 라이트 컬러
    
    // MARK: - HEX Color Helper
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
