import Foundation

// MARK: - 버전 정보 유틸리티
extension Bundle {
    /// 현재 앱 버전 가져오기
    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// 현재 빌드 번호 가져오기
    static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// 버전과 빌드 번호 함께 표시
    static var fullVersion: String {
        return "\(appVersion) (\(buildNumber))"
    }
}


struct Announcement: Identifiable, Codable {
    let id: String
    let title: String
    let content: String
    let version: String
    let date: Date
    let isImportant: Bool
    
    init(id: String = UUID().uuidString, title: String, content: String, version: String, date: Date = Date(), isImportant: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.version = version
        self.date = date
        self.isImportant = isImportant
    }
}

class AnnouncementManager: ObservableObject {
    static let shared = AnnouncementManager()
    
    @Published var announcements: [Announcement] = []
    
    private init() {
        loadAnnouncements()
    }
    
    private func loadAnnouncements() {
        // 기본 공지사항들 (앱 첫 실행 시)
        if announcements.isEmpty {
            // 🔄 동적으로 현재 버전 가져오기
            let currentVersion = Bundle.appVersion
            
            announcements = [
                Announcement(
                    title: "Whiff v\(currentVersion) 출시!",  // ← 수정됨
                    content: """
                    🎉 Whiff 앱이 정식 출시되었습니다!
                    
                    ✨ 주요 기능:
                    • AI 기반 향수 추천 시스템
                    • 향기 일기 작성 및 관리
                    • 개인화된 향수 컬렉션
                    • 커뮤니티 기능
                    
                    앞으로 더 나은 서비스를 위해 노력하겠습니다!
                    """,
                    version: currentVersion,  // ← 수정됨
                    date: Date(),
                    isImportant: true
                ),
                Announcement(
                    title: "온보딩 기능 추가",
                    content: """
                    새로운 사용자를 위한 앱 설명서가 추가되었습니다!
                    
                    📱 추가된 기능:
                    • 앱 첫 실행 시 온보딩 화면
                    • 주요 기능 소개
                    • 프로필에서 언제든 다시보기 가능
                    
                    더욱 편리한 사용을 위해 계속 개선하겠습니다.
                    """,
                    version: currentVersion,  // ← 수정됨
                    date: Date().addingTimeInterval(-86400), // 1일 전
                    isImportant: false
                )
            ]
            saveAnnouncements()
        }
    }
    
    func addAnnouncement(_ announcement: Announcement) {
        announcements.insert(announcement, at: 0) // 최신 공지사항을 맨 위에
        saveAnnouncements()
    }
    
    func removeAnnouncement(_ announcement: Announcement) {
        announcements.removeAll { $0.id == announcement.id }
        saveAnnouncements()
    }
    
    private func saveAnnouncements() {
        if let data = try? JSONEncoder().encode(announcements) {
            UserDefaults.standard.set(data, forKey: "announcements")
        }
    }
    
    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "announcements"),
           let savedAnnouncements = try? JSONDecoder().decode([Announcement].self, from: data) {
            announcements = savedAnnouncements
        }
    }
} 
