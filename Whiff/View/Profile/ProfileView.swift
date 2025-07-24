import SwiftUI
import PhotosUI
import FirebaseAuth
import AuthenticationServices

// MARK: - 일기 데이터 모델

struct DiaryEntry: Identifiable, Codable {
    var id: String
    var title: String
    var content: String
    var date: Date
    var mood: String
    var imageURL: String
    
    init(id: String = UUID().uuidString, title: String, content: String, date: Date = Date(), mood: String = "😊", imageURL: String = "") {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.mood = mood
        self.imageURL = imageURL
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var projectStore: ProjectStore
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var userName = "사용자"
    @State private var showingNameEdit = false
    @State private var diaryEntries: [DiaryEntry] = [] // 일기 엔트리들
    @State private var isSavingProfile = false
    @State private var profileSaveError: String? = nil
    @State private var profileImageData: Data? = nil
    @State private var showingEditProfile = false
    @State private var editUserName = ""
    @State private var editProfileImage: Image? = nil
    @State private var editProfileImageData: Data? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 프로필 헤더
                    ProfileHeaderView(
                        selectedItem: $selectedItem,
                        profileImage: $profileImage,
                        userName: $userName,
                        showingNameEdit: $showingNameEdit,
                        recommendationCount: projectStore.projects.count,
                        diaryCount: diaryEntries.count
                    )
                    
                    // 프로필 편집 버튼
                    Button(action: {
                        editUserName = userName
                        editProfileImage = profileImage
                        editProfileImageData = profileImageData
                        showingEditProfile = true
                    }) {
                        Text("프로필 편집")
                            .font(.subheadline)
                            .foregroundColor(.whiffWhiteText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.whiffPrimary)
                            .cornerRadius(8)
                    }
                    
                    // 일기 관리 섹션
                    DiaryManagementSection(diaryEntries: $diaryEntries)
                    
                    // 향수 추천 기록 섹션
                    PerfumeProjectSection()
                    
                    // 앱 설정 섹션
                    AppSettingsSection()
                    
                    // 공지사항 섹션
                    AnnouncementSection()
                    
                    // 하단 여백
                    Color.clear.frame(height: 50)
                }
            }
            .background(Color.whiffMainBackground)
            .refreshable {
                // 새로고침 시 일기 목록 다시 로드
                loadDiaryEntries()
            }
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: selectedItem) { oldValue, newValue in
                if let newItem = newValue {
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            profileImage = Image(uiImage: uiImage)
                            profileImageData = data
                            // 사진만 바꿔도 바로 저장
                            await saveProfile()
                        }
                    }
                }
            }
            .onAppear {
                loadDiaryEntries()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // 앱이 포그라운드로 올라올 때 일기 목록 새로고침
                loadDiaryEntries()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("DiaryUpdated"))) { _ in
                // 일기가 업데이트될 때 새로고침
                print("📝 [ProfileView] 일기 업데이트 알림 수신")
                loadDiaryEntries()
            }
            .onReceive(Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()) { _ in
                // 2초마다 자동 새로고침 (개발 중에만)
                #if DEBUG
                loadDiaryEntries()
                #endif
            }
            .sheet(isPresented: $showingEditProfile) {
                VStack(spacing: 24) {
                    Text("프로필 편집")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.whiffPrimaryText)
                    // 프로필 이미지
                    PhotosPicker(selection: Binding(get: { nil }, set: { item in
                        if let item = item {
                            Task {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    editProfileImage = Image(uiImage: uiImage)
                                    editProfileImageData = data
                                }
                            }
                        }
                    }), matching: .images) {
                        if let editProfileImage {
                            editProfileImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.whiffSecondaryText2.opacity(0.3), lineWidth: 2))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.whiffPrimary)
                        }
                    }
                    // 이름 입력
                    TextField("이름", text: $editUserName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    HStack(spacing: 16) {
                        Button("취소") {
                            showingEditProfile = false
                        }
                        .foregroundColor(.red)
                        Button("저장") {
                            Task {
                                await saveEditedProfile()
                                showingEditProfile = false
                            }
                        }
                        .foregroundColor(.whiffPrimary)
                    }
                }
                .padding()
                .background(Color.whiffMainBackground)
            }
        }
    }
    
    private func loadDiaryEntries() {
        print("📱 [ProfileView] 일기 목록 로드 시작")
        
        // UserDefaults에서 일기 데이터 불러오기
        if let data = UserDefaults.standard.data(forKey: "diaryEntries"),
           let entries = try? JSONDecoder().decode([DiaryEntry].self, from: data) {
            diaryEntries = entries.sorted { $0.date > $1.date } // 최신순 정렬
            print("✅ [ProfileView] 일기 목록 로드 완료: \(entries.count)개")
            
            // 디버깅: 로드된 일기 내용 확인
            for (index, entry) in entries.enumerated() {
                print("   \(index + 1). \(entry.title) - ID: \(entry.id)")
                print("      날짜: \(entry.date)")
                print("      이미지: \(entry.imageURL.isEmpty ? "없음" : "있음")")
            }
        } else {
            print("📝 [ProfileView] 저장된 일기가 없습니다")
            diaryEntries = []
        }
        
        // 강제로 UI 업데이트
        DispatchQueue.main.async {
            // UI 업데이트 트리거
        }
    }
    
    private func saveProfile() async {
        isSavingProfile = true
        profileSaveError = nil
        
        // 이름 유효성 검사 추가
        guard !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                profileSaveError = "이름을 입력해주세요"
                isSavingProfile = false
            }
            return
        }
        
        var pictureBase64: String? = nil
        if let data = profileImageData {
            pictureBase64 = data.base64EncodedString()
        }
        
        do {
            let req = ProfileUpdateRequest(name: userName, picture: pictureBase64)
            
            // 요청 객체 유효성 확인
            print("🔍 [프로필 저장] 요청 데이터 - 이름: '\(req.name)', 이미지: \(req.picture != nil ? "있음" : "없음")")
            
            let _ = try await APIClient.shared.updateProfile(profileData: req)
            // 저장 성공 시 에러 초기화 및 알림
            await MainActor.run {
                profileSaveError = nil
            }
        } catch {
            print("❌ [프로필 저장 실패] \(error)")
            await MainActor.run {
                profileSaveError = "프로필 저장 중 오류가 발생했습니다. 다시 시도해주세요."
            }
        }
        isSavingProfile = false
    }
    
    private func saveEditedProfile() async {
        isSavingProfile = true
        profileSaveError = nil
        
        // 이름 유효성 검사 추가
        guard !editUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                profileSaveError = "이름을 입력해주세요"
                isSavingProfile = false
            }
            return
        }
        
        var pictureBase64: String? = nil
        if let data = editProfileImageData {
            pictureBase64 = data.base64EncodedString()
        }
        
        do {
            let req = ProfileUpdateRequest(name: editUserName, picture: pictureBase64)
            
            // 요청 객체 유효성 확인
            print("🔍 [프로필 편집 저장] 요청 데이터 - 이름: '\(req.name)', 이미지: \(req.picture != nil ? "있음" : "없음")")
            
            let _ = try await APIClient.shared.updateProfile(profileData: req)
            await MainActor.run {
                userName = editUserName
                profileImage = editProfileImage
                profileImageData = editProfileImageData
                profileSaveError = nil
            }
        } catch {
            print("❌ [프로필 편집 저장 실패] \(error)")
            await MainActor.run {
                profileSaveError = "프로필 저장 중 오류가 발생했습니다. 다시 시도해주세요."
            }
        }
        isSavingProfile = false
    }
}

// MARK: - 프로필 헤더

struct ProfileHeaderView: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var profileImage: Image?
    @Binding var userName: String
    @Binding var showingNameEdit: Bool
    let recommendationCount: Int
    let diaryCount: Int
    
    var body: some View {
        VStack(spacing: 24) {
            // 프로필 이미지와 기본 정보
            VStack(spacing: 16) {
                // 프로필 이미지
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    if let profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.whiffSecondaryText2.opacity(0.3), lineWidth: 2))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.whiffPrimary)
                    }
                }
                
                // 사용자 이름
                HStack {
                    Text(userName)
                        .font(.title)
                        .bold()
                        .foregroundColor(.whiffPrimaryText)
                    
                    Button(action: {
                        showingNameEdit = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.whiffSecondaryText2)
                    }
                }
            }
            
            // 통계 정보
            HStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text("\(recommendationCount)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.whiffPrimary)
                    Text("추천")
                        .font(.subheadline)
                        .foregroundColor(.whiffSecondaryText2)
                }
                
                VStack(spacing: 8) {
                    Text("\(diaryCount)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.whiffPrimary)
                    Text("일기")
                        .font(.subheadline)
                        .foregroundColor(.whiffSecondaryText2)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(Color.whiffSectionBackground)
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
}

// MARK: - 일기 관리 섹션

struct DiaryManagementSection: View {
    @Binding var diaryEntries: [DiaryEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("일기 관리")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.whiffPrimaryText)
                
                Spacer()
                
                NavigationLink(destination: DiaryManagementView()) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("일기 관리")
                    }
                    .font(.subheadline)
                    .foregroundColor(.whiffWhiteText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.whiffPrimary)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                HStack {
                    Text("총 \(diaryEntries.count)개의 일기")
                        .font(.subheadline)
                        .foregroundColor(.whiffSecondaryText2)
                    Spacer()
                }
                .padding(.horizontal)
                
                if diaryEntries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book")
                            .font(.largeTitle)
                            .foregroundColor(.whiffSecondaryText2.opacity(0.6))
                        Text("작성된 일기가 없습니다")
                            .font(.subheadline)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
    }
    
    private func saveDiaryEntries() {
        do {
            let data = try JSONEncoder().encode(diaryEntries)
            UserDefaults.standard.set(data, forKey: "diaryEntries")
            UserDefaults.standard.synchronize() // 강제 동기화
            print("✅ [ProfileView] saveDiaryEntries 완료: \(diaryEntries.count)개")
            
            // 다른 뷰에 알림 전송
            NotificationCenter.default.post(name: Notification.Name("DiaryUpdated"), object: nil)
            print("📢 [ProfileView] saveDiaryEntries 알림 전송")
            
        } catch {
            print("❌ [ProfileView] saveDiaryEntries 실패: \(error)")
        }
    }
}

// MARK: - 향수 추천 기록 섹션
struct PerfumeProjectSection: View {
    @EnvironmentObject var projectStore: ProjectStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("향수 추천 기록")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.whiffPrimaryText)
                
                Spacer()
                
                NavigationLink(destination: SavedProjectsView()) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("관리")
                    }
                    .font(.subheadline)
                    .foregroundColor(.whiffWhiteText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.whiffPrimary)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            
            if projectStore.projects.isEmpty {
                // 빈 상태
                VStack(spacing: 20) {
                    Image(systemName: "drop.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.whiffSecondaryText2.opacity(0.4))
                    
                    VStack(spacing: 12) {
                        Text("아직 추천받은 향수가 없습니다")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.whiffSecondaryText2)
                        
                        Text("향수 추천을 받아 나만의 컬렉션을 만들어보세요")
                            .font(.body)
                            .foregroundColor(.whiffSecondaryText2.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.whiffMainGradient.opacity(0.1))
                .cornerRadius(16)
            } else {
                // 추천 기록 그리드
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(projectStore.projects.prefix(4), id: \.id) { project in
                        HStack {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "drop.circle.fill")
                                        .foregroundColor(.whiffPrimary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(project.name)
                                            .font(.headline)
                                            .lineLimit(1)
                                            .foregroundColor(.whiffPrimaryText)
                                        Text("\(project.recommendations.count)개 향수")
                                            .font(.caption)
                                            .foregroundColor(.whiffSecondaryText2)
                                    }
                                    Spacer()
                                }
                                
                                HStack {
                                    ForEach(project.recommendations.prefix(3), id: \.id) { perfume in
                                        AsyncImage(url: URL(string: perfume.imageURL)) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 40, height: 50)
                                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                            default:
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.whiffSectionBackground)
                                                    .frame(width: 40, height: 50)
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color.whiffMainBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 2)
                        }
                        .foregroundColor(.whiffPrimaryText)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - 일기 관련 뷰들

struct DiaryManagementView: View {
    @State private var diaryEntries: [DiaryEntry] = []
    @State private var showingDiaryDetail = false
    @State private var selectedDiary: DiaryEntry?
    
    var body: some View {
        NavigationView {
            List {
                // 통계 섹션
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("총 \(diaryEntries.count)개")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.whiffPrimaryText)
                            Text("시향 일기 \(diaryEntries.filter { $0.title.contains("시향 일기") }.count)개")
                                .font(.caption)
                                .foregroundColor(.whiffSecondaryText2)
                        }
                        Spacer()
                        Image(systemName: "book.fill")
                            .foregroundColor(.whiffPrimary)
                            .font(.title2)
                    }
                    .padding(.vertical, 8)
                }
                
                // 일기 목록 섹션
                if !diaryEntries.isEmpty {
                    Section("일기 목록") {
                        ForEach(diaryEntries.sorted(by: { $0.date > $1.date })) { entry in
                            HStack(spacing: 12) {
                                // 기분 이모지
                                Text(entry.mood)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    // 제목
                                    Text(entry.title.isEmpty || entry.title == "제목 없음" ? "일기" : entry.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .foregroundColor(.whiffPrimaryText)
                                    
                                    // 내용 미리보기
                                    if !entry.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text(entry.content)
                                            .font(.caption)
                                            .foregroundColor(.whiffSecondaryText2)
                                            .lineLimit(1)
                                    }
                                    
                                    // 날짜
                                    Text(formatDate(entry.date))
                                        .font(.caption2)
                                        .foregroundColor(.whiffSecondaryText2)
                                }
                                
                                Spacer()
                                
                                // 타입 아이콘
                                if entry.title.contains("시향 일기") {
                                    Image(systemName: "drop.fill")
                                        .font(.caption)
                                        .foregroundColor(.whiffPrimary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDiary = entry
                                showingDiaryDetail = true
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("삭제") {
                                    deleteDiary(entry)
                                }
                                .tint(.red)
                            }
                        }
                    }
                } else {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "book")
                                    .font(.largeTitle)
                                    .foregroundColor(.whiffSecondaryText2)
                                Text("일기가 없습니다")
                                    .font(.subheadline)
                                    .foregroundColor(.whiffSecondaryText2)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .background(Color.whiffMainBackground)
            .navigationTitle("일기 관리")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                loadDiaryEntries()
            }
            .sheet(isPresented: $showingDiaryDetail) {
                if let diary = selectedDiary {
                    DiaryEntryDetailView(entry: diary)
                }
            }
            .onAppear {
                loadDiaryEntries()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "오늘"
        } else if Calendar.current.isDateInYesterday(date) {
            return "어제"
        } else {
            formatter.dateFormat = "M월 d일"
            return formatter.string(from: date)
        }
    }
    
    private func deleteDiary(_ diary: DiaryEntry) {
        if let index = diaryEntries.firstIndex(where: { $0.id == diary.id }) {
            diaryEntries.remove(at: index)
            
            // UserDefaults에 즉시 저장
            do {
                let data = try JSONEncoder().encode(diaryEntries)
                UserDefaults.standard.set(data, forKey: "diaryEntries")
                UserDefaults.standard.synchronize() // 강제 동기화
                print("✅ [ProfileView] 일기 삭제 후 저장 완료: \(diaryEntries.count)개")
                
                // 다른 뷰에 알림 전송
                NotificationCenter.default.post(name: Notification.Name("DiaryUpdated"), object: nil)
                print("📢 [ProfileView] 일기 삭제 알림 전송")
                
            } catch {
                print("❌ [ProfileView] 일기 삭제 후 저장 실패: \(error)")
            }
        }
    }
    
    private func loadDiaryEntries() {
        // UserDefaults에서 일기 데이터 불러오기
        if let data = UserDefaults.standard.data(forKey: "diaryEntries"),
           let entries = try? JSONDecoder().decode([DiaryEntry].self, from: data) {
            diaryEntries = entries.sorted { $0.date > $1.date } // 최신순 정렬
            print("✅ [ProfileView] 일기 목록 로드 완료: \(entries.count)개")
            
            // 디버깅: 로드된 일기 내용 확인
            for (index, entry) in entries.enumerated() {
                print("   \(index + 1). \(entry.title) - \(entry.content.prefix(30))...")
                print("      날짜: \(entry.date)")
                print("      이미지: \(entry.imageURL.isEmpty ? "없음" : "있음")")
            }
        } else {
            print("📝 [ProfileView] 저장된 일기가 없습니다")
            diaryEntries = []
        }
        
        // 강제로 UI 업데이트
        DispatchQueue.main.async {
            // UI 업데이트 트리거
        }
    }
    
    private func saveDiaryEntries() {
        if let data = try? JSONEncoder().encode(diaryEntries) {
            UserDefaults.standard.set(data, forKey: "diaryEntries")
        }
    }
}

struct DiaryEntryDetailView: View {
    let entry: DiaryEntry
    @State private var showingActionSheet = false
    @State private var showingReportSheet = false
    @State private var reportReason = ""
    @State private var showReportSuccess = false
    @State private var showReportError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 헤더 영역
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        Text(entry.mood)
                            .font(.system(size: 60))
                            .frame(width: 80, height: 80)
                            .background(
                                LinearGradient(
                                                                    gradient: Gradient(colors: [Color.whiffPrimary.opacity(0.1), Color.whiffGradientStart.opacity(0.3)]),
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.whiffPrimaryText)
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.whiffPrimary)
                                Text(formatFullDate(entry.date))
                                    .font(.subheadline)
                                    .foregroundColor(.whiffSecondaryText2)
                            }
                            if entry.title.contains("시향 일기") {
                                HStack(spacing: 6) {
                                    Image(systemName: "drop.circle.fill")
                                        .foregroundColor(.whiffPrimary)
                                    Text("시향 일기")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.whiffPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.whiffPrimary.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        Spacer()
                        // 점 세 개 버튼
                        Button(action: {
                            showingActionSheet = true
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.title2)
                                .foregroundColor(.whiffSecondaryText2)
                        }
                        .actionSheet(isPresented: $showingActionSheet) {
                            ActionSheet(
                                title: Text("더보기"),
                                buttons: [
                                    .destructive(Text("신고하기")) { showingReportSheet = true },
                                    .cancel()
                                ]
                            )
                        }
                    }
                }
                .padding()
                .background(Color.whiffSectionBackground)
                
                // 이미지 영역 (있을 경우)
                if !entry.imageURL.isEmpty {
                    AsyncImage(url: URL(string: entry.imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 400)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                        case .failure(_):
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.whiffSectionBackground)
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.artframe")
                                            .font(.largeTitle)
                                            .foregroundColor(.whiffSecondaryText2)
                                        Text("이미지를 불러올 수 없습니다")
                                            .font(.caption)
                                            .foregroundColor(.whiffSecondaryText2)
                                    }
                                )
                                .padding(.horizontal)
                        case .empty:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.whiffSectionBackground)
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                        Text("이미지 로딩 중...")
                                            .font(.caption)
                                            .foregroundColor(.whiffSecondaryText2)
                                    }
                                )
                                .padding(.horizontal)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.vertical)
                }
                
                // 내용 영역
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "text.quote")
                                .foregroundColor(.whiffPrimary)
                                .font(.title2)
                            Text("일기 내용")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.whiffPrimaryText)
                            Spacer()
                        }
                        
                        Text(entry.content)
                            .font(.body)
                            .lineSpacing(8)
                            .padding(.leading, 8)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.whiffPrimaryText)
                    }
                    
                    // 구분선
                    Divider()
                        .foregroundColor(.whiffSecondaryText2)
                        .padding(.vertical, 8)
                    
                    // 추가 정보
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.whiffPrimary)
                            Text("작성 정보")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.whiffPrimaryText)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            InfoRow(icon: "clock", title: "작성 시간", content: formatTimeOnly(entry.date))
                            InfoRow(icon: "heart", title: "기분", content: "\(entry.mood) 기분")
                            
                            if entry.title.contains("시향 일기") {
                                InfoRow(icon: "drop", title: "카테고리", content: "시향 일기")
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
                .background(Color.whiffMainBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .whiffPrimaryText.opacity(0.05), radius: 10, x: 0, y: -5)
            }
        }
        .background(Color.whiffMainBackground)
        // 신고 사유 입력 Sheet
        .sheet(isPresented: $showingReportSheet) {
            VStack(spacing: 24) {
                Text("신고 사유를 입력하세요")
                    .font(.headline)
                    .foregroundColor(.whiffPrimaryText)
                TextField("신고 사유", text: $reportReason)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.whiffMainBackground)
                Button("신고 제출") {
                    reportDiary()
                }
                .foregroundColor(.whiffWhiteText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.whiffPrimary)
                .cornerRadius(8)
                .disabled(reportReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding()
                .background(Color.whiffMainBackground)
            }
            .padding()
            .background(Color.whiffMainBackground)  
        }
        // 신고 성공/실패 알림
        .alert(isPresented: $showReportSuccess) {
            Alert(title: Text("신고 완료"), message: Text("신고가 정상적으로 접수되었습니다."), dismissButton: .default(Text("확인")))
        }
        .alert(isPresented: $showReportError) {
            Alert(title: Text("신고 실패"), message: Text("신고 중 오류가 발생했습니다. 다시 시도해주세요."), dismissButton: .default(Text("확인")))
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private func reportDiary() {
        guard let url = URL(string: "https://whiff-api-9nd8.onrender.com/reports/diary") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "target_id": entry.id,
            "reason": reportReason
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                showingReportSheet = false
                reportReason = ""
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    showReportSuccess = true
                } else {
                    showReportError = true
                }
            }
        }.resume()
    }
}

// MARK: - 정보 행 컴포넌트
struct InfoRow: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.whiffPrimary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.whiffSecondaryText2)
                Text(content)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.whiffPrimaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 저장된 프로젝트 전체 관리 뷰
struct SavedProjectsView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showingDeleteAlert = false
    @State private var projectToDelete: Project?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if projectStore.projects.isEmpty {
                        EmptyRecommendationView()
                    } else {
                        ForEach(projectStore.projects.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { project in
                            ProjectDetailCard(
                                project: project,
                                onDelete: {
                                    projectToDelete = project
                                    showingDeleteAlert = true
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(Color.whiffMainBackground)
            }
            .background(Color.whiffMainBackground)
            .navigationTitle("추천 향수 관리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !projectStore.projects.isEmpty {
                        Button("전체 삭제") {
                            showingDeleteAlert = true
                            projectToDelete = nil // 전체 삭제를 위한 nil
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("삭제 확인", isPresented: $showingDeleteAlert) {
                if let project = projectToDelete {
                    Button("취소", role: .cancel) { }
                    Button("삭제", role: .destructive) {
                        projectStore.removeProject(project)
                    }
                } else {
                    Button("취소", role: .cancel) { }
                    Button("전체 삭제", role: .destructive) {
                        projectStore.clearRecommendations()
                    }
                }
            } message: {
                if projectToDelete != nil {
                    Text("이 추천 프로젝트를 삭제하시겠습니까?")
                } else {
                    Text("모든 추천 기록을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.")
                }
            }
        }
    }
}

// MARK: - 프로젝트 상세 카드
struct ProjectDetailCard: View {
    let project: Project
    let onDelete: () -> Void
    @State private var showingActionSheet = false
    @State private var showingReportSheet = false
    @State private var reportReason = ""
    @State private var showReportSuccess = false
    @State private var showReportError = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .bold()
                        .foregroundColor(.whiffPrimaryText)
                    
                    HStack(spacing: 12) {
                        Text("\(project.recommendations.count)개 향수")
                            .font(.caption)
                            .foregroundColor(.whiffPrimary)
                        
                        Text(project.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                }
                
                Spacer()
                
                // 점 세 개 버튼 (ActionSheet)
                Button(action: {
                    showingActionSheet = true
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.whiffSecondaryText2)
                }
                .actionSheet(isPresented: $showingActionSheet) {
                    ActionSheet(
                        title: Text("더보기"),
                        buttons: [
                            .destructive(Text("신고하기")) { showingReportSheet = true },
                            .cancel()
                        ]
                    )
                }
            }
            
            // 태그들
            if !project.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(project.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.whiffPrimary.opacity(0.1))
                                .foregroundColor(.whiffPrimary)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 1) // 스크롤 가능한 영역 표시
                }
            }
            
            // 향수 미리보기 (최대 3개)
            HStack(spacing: 12) {
                ForEach(project.recommendations.prefix(3), id: \.id) { perfume in
                    VStack(spacing: 6) {
                        AsyncImage(url: URL(string: perfume.imageURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.whiffSecondaryText2.opacity(0.2))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.whiffSecondaryText2)
                                        .font(.caption)
                                )
                        }
                        .frame(width: 60, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Text(perfume.name)
                            .font(.caption2)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(width: 60)
                            .foregroundColor(.whiffPrimaryText)
                    }
                }
                
                if project.recommendations.count > 3 {
                    VStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.whiffSecondaryText2.opacity(0.1))
                            .frame(width: 60, height: 80)
                            .overlay(
                                Text("+\(project.recommendations.count - 3)")
                                    .font(.caption)
                                    .foregroundColor(.whiffSecondaryText2)
                            )
                        
                        Text("더보기")
                            .font(.caption2)
                            .foregroundColor(.whiffSecondaryText2)
                            .frame(width: 60)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.whiffMainBackground)
        .cornerRadius(16)
        .shadow(color: .whiffPrimaryText.opacity(0.05), radius: 4, x: 0, y: 2)
        // 신고 사유 입력 Sheet
        .sheet(isPresented: $showingReportSheet) {
            VStack(spacing: 24) {
                Text("신고 사유를 입력하세요")
                    .font(.headline)
                    .foregroundColor(.whiffPrimaryText)
                TextField("신고 사유", text: $reportReason)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.whiffMainBackground)
                Button("신고 제출") {
                    reportProject()
                }
                .foregroundColor(.whiffWhiteText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.whiffPrimary)
                .cornerRadius(8)
                .disabled(reportReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding()
                .background(Color.whiffMainBackground)
            }
            .padding()
            .background(Color.whiffMainBackground)
        }
        // 신고 성공/실패 알림
        .alert(isPresented: $showReportSuccess) {
            Alert(title: Text("신고 완료"), message: Text("신고가 정상적으로 접수되었습니다."), dismissButton: .default(Text("확인")))
        }
        .alert(isPresented: $showReportError) {
            Alert(title: Text("신고 실패"), message: Text("신고 중 오류가 발생했습니다. 다시 시도해주세요."), dismissButton: .default(Text("확인")))
        }
    }
    
    private func reportProject() {
        // /reports/diary 엔드포인트로 POST 요청
        guard let url = URL(string: "https://whiff-api-9nd8.onrender.com/reports/diary") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "target_id": project.id,
            "reason": reportReason
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("신고 실패: \(error)")
                    showReportError = true
                } else {
                    showReportSuccess = true
                }
                showingReportSheet = false
                reportReason = ""
            }
        }.resume()
    }
}

// MARK: - Empty 상태 뷰
struct EmptyRecommendationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.whiffSecondaryText2.opacity(0.4))
            
            VStack(spacing: 12) {
                Text("아직 추천받은 향수가 없습니다")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.whiffSecondaryText2)
                
                Text("향수 추천을 받아 나만의 컬렉션을 만들어보세요")
                    .font(.body)
                    .foregroundColor(.whiffSecondaryText2.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - 앱 설정 섹션
struct AppSettingsSection: View {
    @StateObject private var appSettings = AppSettings.shared
    @State private var showingOnboarding = false
    @State private var tempOnboardingState = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingWithdrawAlert = false
    @State private var isWithdrawing = false
    @State private var withdrawError: String? = nil
    @State private var isAppleReauthenticating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("앱 설정")
                .font(.title2)
                .bold()
                .foregroundColor(.whiffPrimaryText)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                // 온보딩 다시보기
                Button(action: {
                    tempOnboardingState = true
                    showingOnboarding = true
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.whiffPrimary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("앱 설명서 다시보기")
                                .font(.body)
                                .foregroundColor(.whiffPrimaryText)
                            Text("Whiff 앱의 주요 기능을 다시 확인해보세요")
                                .font(.caption)
                                .foregroundColor(.whiffSecondaryText2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color.whiffMainBackground)
                
                Divider()
                    .padding(.leading, 68)
                
                // 회원 탈퇴 버튼
                Button(action: {
                    showingWithdrawAlert = true
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        Text("회원 탈퇴")
                            .font(.body)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color.whiffMainBackground)
                .alert("정말로 회원 탈퇴하시겠습니까?", isPresented: $showingWithdrawAlert) {
                    Button("취소", role: .cancel) {}
                    Button("탈퇴", role: .destructive) {
                        Task {
                            // Apple 사용자인지 확인
                            let savedAppleInfo = AppleSignInUtils.getSavedAppleUserInfo()
                            if savedAppleInfo.userID != nil {
                                print("🍎 [탈퇴버튼] Apple 사용자 감지, 재인증 방식 사용")
                                await withdrawWithAppleReauth()
                            } else {
                                print("👤 [탈퇴버튼] 일반 사용자, 기본 방식 사용")
                                await withdrawUser()
                            }
                        }
                    }
                } message: {
                    Text("탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.")
                }
                
                if let withdrawError = withdrawError {
                    Text(withdrawError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 20)
                }
                
                Divider()
                    .padding(.leading, 68)
                
                // 앱 정보
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.whiffSecondaryText2)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("앱 정보")
                            .font(.body)
                            .foregroundColor(.whiffPrimaryText)
                        Text("버전 1.0.0")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.whiffMainBackground)
                
                // 로그아웃 버튼
                Button(action: {
                    authViewModel.signOut()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.whiffPrimary)
                            .frame(width: 24)
                        Text("로그아웃")
                            .font(.body)
                            .foregroundColor(.whiffPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color.whiffMainBackground)
            }
            .background(Color.whiffSectionBackground)
            .cornerRadius(16)
            .padding(.horizontal)
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(isFirstLaunch: $tempOnboardingState)
                .onChange(of: tempOnboardingState) { oldValue, newValue in
                    // 온보딩이 완료되면 화면 닫기
                    if !newValue {
                        showingOnboarding = false
                    }
                }
        }
    }
    
    private func withdrawUser() async {
        isWithdrawing = true
        withdrawError = nil
        
        // 디버깅: 현재 사용자 정보 확인
        print("🔍 [회원탈퇴] 시작")
        print("🔍 [회원탈퇴] 현재 Firebase 사용자: \(Auth.auth().currentUser?.uid ?? "없음")")
        print("🔍 [회원탈퇴] 저장된 사용자 ID: \(UserDefaults.standard.string(forKey: "userId") ?? "없음")")
        
        // Apple 사용자 정보 확인
        let savedAppleInfo = AppleSignInUtils.getSavedAppleUserInfo()
        let isAppleUser = savedAppleInfo.userID != nil
        print("🔍 [회원탈퇴] Apple 사용자 여부: \(isAppleUser)")
        if isAppleUser {
            print("🔍 [회원탈퇴] Apple User ID: \(savedAppleInfo.userID ?? "없음")")
            print("🔍 [회원탈퇴] Apple Email: \(savedAppleInfo.email ?? "없음")")
        }
        
        do {
            // 1. Apple 사용자인 경우 토큰 강제 갱신
            if isAppleUser, let currentUser = Auth.auth().currentUser {
                print("🍎 [회원탈퇴] Apple 사용자 - Firebase 토큰 강제 갱신 시도")
                do {
                    let freshToken = try await currentUser.getIDToken(forcingRefresh: true)
                    UserDefaults.standard.set(freshToken, forKey: "authToken")
                    print("✅ [회원탈퇴] Firebase 토큰 갱신 완료")
                    
                    // 토큰 길이 확인 (디버깅)
                    print("🔍 [회원탈퇴] 갱신된 토큰 길이: \(freshToken.count)자")
                } catch {
                    print("⚠️ [회원탈퇴] 토큰 갱신 실패: \(error.localizedDescription)")
                    // 토큰 갱신 실패해도 계속 진행
                }
            }
            
            // 2. 현재 저장된 토큰 확인
            if let token = UserDefaults.standard.string(forKey: "authToken") {
                print("🔍 [회원탈퇴] 사용할 토큰 길이: \(token.count)자")
                print("🔍 [회원탈퇴] 토큰 시작 부분: \(String(token.prefix(50)))...")
            } else {
                print("❌ [회원탈퇴] 저장된 토큰이 없음")
                throw APIError.invalidToken
            }
            
            // 3. 백엔드 서버에서 회원 탈퇴 처리
            print("🔄 [회원탈퇴] 서버 API 호출 시작")
            let _ = try await APIClient.shared.withdrawUser()
            print("✅ [회원탈퇴] 서버 탈퇴 처리 완료")
            
            // 4. Apple 사용자 정보 명시적 삭제
            if isAppleUser {
                AppleSignInUtils.clearAppleUserInfo()
                print("✅ [회원탈퇴] Apple 사용자 정보 삭제 완료")
            }
            
            // 5. Firebase 사용자 삭제 시도 (실패해도 무시)
            if let currentUser = Auth.auth().currentUser {
                do {
                    try await currentUser.delete()
                    print("✅ [회원탈퇴] Firebase 사용자 삭제 완료")
                } catch {
                    print("⚠️ [회원탈퇴] Firebase 사용자 삭제 실패 (무시): \(error.localizedDescription)")
                    // Firebase 삭제 실패는 무시하고 계속 진행
                }
            }
            
            // 6. 로그아웃 처리
            await MainActor.run {
                authViewModel.signOut()
                print("✅ [회원탈퇴] 로그아웃 완료")
            }
            
        } catch let apiError as APIError {
            await MainActor.run {
                // 더 구체적인 에러 메시지 제공
                if apiError.localizedDescription.contains("인증 만료") || apiError.localizedDescription.contains("401") {
                    withdrawError = "인증이 만료되었습니다. 다시 로그인 후 시도해주세요."
                } else if apiError.localizedDescription.contains("502") || apiError.localizedDescription.contains("503") {
                    withdrawError = "서버가 일시적으로 응답하지 않습니다. 잠시 후 다시 시도해주세요."
                } else {
                    withdrawError = "회원 탈퇴 중 오류가 발생했습니다: \(apiError.localizedDescription)"
                }
            }
            print("❌ [회원탈퇴] API 오류: \(apiError.localizedDescription)")
            
        } catch {
            await MainActor.run {
                withdrawError = "회원 탈퇴 중 알 수 없는 오류가 발생했습니다: \(error.localizedDescription)"
            }
            print("❌ [회원탈퇴] 알 수 없는 오류: \(error.localizedDescription)")
        }
        
        isWithdrawing = false
        print("🏁 [회원탈퇴] 프로세스 종료")
    }
    // Apple 재인증 후 탈퇴 함수
    private func withdrawWithAppleReauth() async {
        print("🍎 [재인증] Apple 재인증 탈퇴 시작")
        
        // Apple 사용자인지 확인
        let savedAppleInfo = AppleSignInUtils.getSavedAppleUserInfo()
        guard let appleUserID = savedAppleInfo.userID else {
            print("🍎 [재인증] Apple 사용자가 아님, 일반 탈퇴 진행")
            await withdrawUser()
            return
        }
        
        print("🍎 [재인증] Apple User ID 확인: \(appleUserID)")
        
        await MainActor.run {
            isAppleReauthenticating = true
        }
        
        do {
            // 토큰 여러 번 갱신 시도
            await attemptMultipleTokenRefresh()
            
            // 재인증 후 탈퇴 진행
            await withdrawUser()
            
        } catch {
            await MainActor.run {
                withdrawError = "Apple 재인증 중 오류가 발생했습니다: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isAppleReauthenticating = false
        }
    }

    // 토큰 여러 번 갱신 시도
    private func attemptMultipleTokenRefresh() async {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ [토큰갱신] Firebase 사용자 없음")
            return
        }
        
        // 최대 3번 시도
        for attempt in 1...3 {
            do {
                print("🔄 [토큰갱신] 시도 \(attempt)/3")
                
                let freshToken = try await currentUser.getIDToken(forcingRefresh: true)
                UserDefaults.standard.set(freshToken, forKey: "authToken")
                
                print("✅ [토큰갱신] 성공 (시도 \(attempt))")
                
                break // 성공하면 반복 종료
                
            } catch {
                print("❌ [토큰갱신] 시도 \(attempt) 실패: \(error.localizedDescription)")
                
                if attempt < 3 {
                    // 1초 대기 후 재시도
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
    }
}

// MARK: - 공지사항 섹션
struct AnnouncementSection: View {
    @StateObject private var announcementManager = AnnouncementManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("공지사항")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.whiffPrimaryText)
                
                Spacer()
                
                // 새로운 공지사항이 있으면 알림 표시
                if hasNewAnnouncements {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
                
                NavigationLink(destination: AnnouncementListView()) {
                    HStack(spacing: 6) {
                        Image(systemName: "megaphone")
                        Text("전체보기")
                    }
                    .font(.subheadline)
                    .foregroundColor(.whiffWhiteText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.whiffPrimary)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            
            if announcementManager.announcements.isEmpty {
                // 빈 상태
                VStack(spacing: 20) {
                    Image(systemName: "megaphone")
                        .font(.system(size: 50))
                        .foregroundColor(.whiffSecondaryText2.opacity(0.4))
                    
                    VStack(spacing: 12) {
                        Text("공지사항이 없습니다")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.whiffSecondaryText2)
                        
                        Text("새로운 업데이트나 공지사항이 있을 때\n여기에 표시됩니다")
                            .font(.body)
                            .foregroundColor(.whiffSecondaryText2.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // 최신 공지사항 3개만 표시
                VStack(spacing: 0) {
                    ForEach(Array(announcementManager.announcements.prefix(3).enumerated()), id: \.element.id) { index, announcement in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(announcement.title)
                                        .font(.body)
                                        .foregroundColor(.whiffPrimaryText)
                                        .lineLimit(1)
                                    
                                    if announcement.isImportant {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("v\(announcement.version)")
                                        .font(.caption)
                                        .foregroundColor(.whiffWhiteText)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.whiffPrimary.opacity(0.8))
                                        .cornerRadius(6)
                                    
                                    Text(announcement.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.whiffSecondaryText2)
                                    
                                    Spacer()
                                }
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.whiffSecondaryText2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        // 마지막 요소가 아닐 때만 Divider 추가
                        if index < min(2, announcementManager.announcements.count - 1) {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
                .background(Color.whiffMainBackground)
            }
        }
    }
    
    private var hasNewAnnouncements: Bool {
        // 최근 7일 내의 공지사항이 있으면 새로운 것으로 간주
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return announcementManager.announcements.contains { $0.date > oneWeekAgo }
    }
} 

