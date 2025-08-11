import Foundation
import Network

@MainActor
class DailyPerfumeManager: ObservableObject {
    static let shared = DailyPerfumeManager()
    
    @Published var todaysPerfume: Perfume?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let networkManager = NetworkManager.shared
    private let userDefaults = UserDefaults.standard
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // 재시도 설정
    private let maxRetryCount = 3
    private let retryDelay: TimeInterval = 2.0
    
    private init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            Task { @MainActor in
                if path.status == .satisfied {
                    print("오늘의 향수] 네트워크 연결됨")
                } else {
                    print("오늘의 향수] 네트워크 연결 안됨")
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func getTodaysPerfume() async {
        print("오늘의 향수] getTodaysPerfume 시작")
        
        // 오늘 날짜 확인
        let today = Calendar.current.startOfDay(for: Date())
        let lastUpdateDate = userDefaults.object(forKey: "lastPerfumeUpdateDate") as? Date ?? Date.distantPast
        
        // 같은 날이면 저장된 향수 사용
        if Calendar.current.isDate(today, inSameDayAs: lastUpdateDate) {
            if let savedPerfumeData = userDefaults.data(forKey: "todaysPerfume"),
               let savedPerfume = try? JSONDecoder().decode(Perfume.self, from: savedPerfumeData) {
                print("오늘의 향수] 저장된 향수 사용: \(savedPerfume.name)")
                self.todaysPerfume = savedPerfume
                return
            }
        }
        
        print("오늘의 향수] 새로운 향수 요청 필요")
        // 새로운 날이면 새로운 향수 선택
        await fetchNewDailyPerfume()
    }
    
    private func fetchNewDailyPerfume() async {
        self.isLoading = true
        self.error = nil
        
        var retryCount = 0
        
        while retryCount < maxRetryCount {
            do {
                print("오늘의 향수] API 호출 시작... (시도 \(retryCount + 1)/\(maxRetryCount))")
                let perfumes = try await networkManager.fetchPerfumes()
                print("오늘의 향수] API 응답 성공 - 향수 개수: \(perfumes.count)")
                
                guard !perfumes.isEmpty else {
                    print("오늘의 향수] 오류 - 받은 향수 목록이 비어있음")
                    throw NetworkError.invalidData
                }
                
                // 날짜 기반 시드로 랜덤 향수 선택 (매일 동일한 향수 보장)
                let today = Calendar.current.startOfDay(for: Date())
                let seed = Int(today.timeIntervalSince1970) / 86400 // 날짜별로 고유한 시드
                srand48(seed)
                let randomIndex = Int(drand48() * Double(perfumes.count))
                let basicPerfume = perfumes[randomIndex]
                print("오늘의 향수] 기본 향수 선택: \(basicPerfume.name) - \(basicPerfume.brand)")
                
                // 상세 정보 가져오기 시도
                var finalPerfume = basicPerfume
                do {
                    print("오늘의 향수] 상세 정보 요청 중...")
                    let detailedPerfume = try await networkManager.fetchPerfumeDetail(name: basicPerfume.name)
                    print("오늘의 향수] 상세 정보 획득 성공")
                    finalPerfume = detailedPerfume
                } catch {
                    print("오늘의 향수] 상세 정보 가져오기 실패: \(error)")
                    print("오늘의 향수] 기본 정보로 대체")
                    // 기본 향수 정보를 그대로 사용
                }
                
                // 선택된 향수와 날짜 저장
                if let encodedPerfume = try? JSONEncoder().encode(finalPerfume) {
                    userDefaults.set(encodedPerfume, forKey: "todaysPerfume")
                    userDefaults.set(today, forKey: "lastPerfumeUpdateDate")
                    print("오늘의 향수] UserDefaults 저장 완료")
                }
                
                self.todaysPerfume = finalPerfume
                self.isLoading = false
                print("오늘의 향수] UI 업데이트 완료 - \(finalPerfume.name)")
                return
                
            } catch {
                print("오늘의 향수] API 호출 실패 (시도 \(retryCount + 1)): \(error)")
                
                retryCount += 1
                if retryCount < maxRetryCount {
                    print("오늘의 향수] \(retryDelay)초 후 재시도...")
                    try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }
        
        // 모든 재시도 실패 시 캐시된 향수 또는 대체 데이터 사용
        print("오늘의 향수] 모든 재시도 실패")
        self.error = NetworkError.serverError
        self.isLoading = false
        await useBackupPerfume()
    }
    
    // 캐시된 향수 또는 개선된 대체 향수 데이터 사용
    private func useBackupPerfume() async {
        print("오늘의 향수] 백업 데이터 사용")
        
        // 1. 이전에 저장된 향수가 있으면 사용
        if let savedPerfumeData = userDefaults.data(forKey: "todaysPerfume"),
           let savedPerfume = try? JSONDecoder().decode(Perfume.self, from: savedPerfumeData) {
            print("오늘의 향수] 이전 저장된 향수 사용: \(savedPerfume.name)")
            self.todaysPerfume = savedPerfume
            return
        }
        
        // 2. 더 풍부한 대체 향수 데이터 사용
        let today = Calendar.current.startOfDay(for: Date())
        let seed = Int(today.timeIntervalSince1970) / 86400
        srand48(seed)
        
        let fallbackPerfumes = createFallbackPerfumes()
        let randomIndex = Int(drand48() * Double(fallbackPerfumes.count))
        let selectedPerfume = fallbackPerfumes[randomIndex]
        
        print("오늘의 향수] 대체 데이터 사용: \(selectedPerfume.name)")
        
        // 오늘 날짜로 저장 (다음에 API가 성공하면 업데이트됨)
        if let encodedPerfume = try? JSONEncoder().encode(selectedPerfume) {
            userDefaults.set(encodedPerfume, forKey: "todaysPerfume")
            userDefaults.set(today, forKey: "lastPerfumeUpdateDate")
        }
        
        self.todaysPerfume = selectedPerfume
        print("오늘의 향수] 대체 데이터 설정 완료")
    }
    
    // 더 다양하고 실제적인 대체 향수 데이터 생성
    private func createFallbackPerfumes() -> [Perfume] {
        return PerfumeDataUtils.createRealisticPerfumes()
    }
    
    // 수동으로 새로운 향수 가져오기
    func refreshTodaysPerfume() async {
        // 강제로 새로운 향수 선택
        userDefaults.removeObject(forKey: "lastPerfumeUpdateDate")
        await fetchNewDailyPerfume()
    }
    
    deinit {
        monitor.cancel()
    }
} 