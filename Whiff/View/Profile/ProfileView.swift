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
                loadUserProfile()
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
                loadUserProfile()
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
                                                        loadUserProfile()
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
                            
                            // MARK: - 사용자 정보 로딩
                            private func loadUserProfile() {
                                print("👤 [ProfileView] 사용자 프로필 로드 시작")
                                // 현재 userName 값 확인
                                    print("🔍 [ProfileView] 현재 userName: '\(userName)'")
                                
                                // 여러 키에서 사용자 이름 시도 (우선순위 순서)
                                // ✅ 수정: 우선순위 변경 - 사용자가 직접 변경한 이름을 최우선으로
                                let userNameKeys = ["userEditedName", "currentUserName", "userName", "appleUserName"]
                                // 모든 키의 값 확인
                                    for key in userNameKeys {
                                        let value = UserDefaults.standard.string(forKey: key)
                                        print("🔍 [ProfileView] \(key): '\(value ?? "nil")'")
                                    }
                                
                                for key in userNameKeys {
                                        if let savedName = UserDefaults.standard.string(forKey: key), !savedName.isEmpty {
                                            print("📝 [ProfileView] userName 변경: '\(userName)' → '\(savedName)'")
                                            userName = savedName
                                            print("✅ [ProfileView] 사용자 이름 로드 성공 (\(key)): \(savedName)")
                                            break
                                    }
                                }
        
                                
                                // 프로필 이미지도 로드 시도
                                if let savedImageKey = UserDefaults.standard.string(forKey: "currentUserProfileImage"),
                                   !savedImageKey.isEmpty,
                                   savedImageKey != "default_profile" {
                                    // 필요하다면 이미지 로드 로직 추가
                                    print("📷 [ProfileView] 프로필 이미지 키 발견: \(savedImageKey)")
                                }
                                
                                print("👤 [ProfileView] 최종 사용자 이름: \(userName)")
                            }
                            
                            private func loadDiaryEntries() {
                                print("📱 [ProfileView] 일기 목록 로드 시작")
                                
                                if let data = UserDefaults.standard.data(forKey: "diaryEntries"),
                                   let entries = try? JSONDecoder().decode([DiaryEntry].self, from: data) {
                                    
                                    // 이미지 URL 검증 및 수정
                                    let validatedEntries = entries.map { entry in
                                        var updatedEntry = entry
                                        if !entry.imageURL.isEmpty {
                                            // file:// URL 검증
                                            if entry.imageURL.hasPrefix("file://") {
                                                if let url = URL(string: entry.imageURL),
                                                   !FileManager.default.fileExists(atPath: url.path) {
                                                    print("⚠️ [프로필 일기] 이미지 파일 없음: \(entry.imageURL)")
                                                    
                                                    // 파일명만 추출해서 현재 Documents 디렉토리에서 찾기
                                                    let fileName = url.lastPathComponent
                                                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                                                    let correctURL = documentsPath.appendingPathComponent(fileName)
                                                    
                                                    if FileManager.default.fileExists(atPath: correctURL.path) {
                                                        updatedEntry.imageURL = correctURL.absoluteString
                                                        print("✅ [프로필 일기] 이미지 URL 수정 완료: \(correctURL.absoluteString)")
                                                    } else {
                                                        print("❌ [프로필 일기] 올바른 파일도 찾을 수 없음: \(fileName)")
                                                        updatedEntry.imageURL = ""
                                                    }
                                                }
                                            }
                                        }
                                        return updatedEntry
                                    }
                                    
                                    // 수정된 데이터가 있으면 저장
                                    let hasChanges = validatedEntries.contains { entry in
                                        if let original = entries.first(where: { $0.id == entry.id }) {
                                            return original.imageURL != entry.imageURL
                                        }
                                        return false
                                    }
                                    
                                    if hasChanges {
                                        do {
                                            let updatedData = try JSONEncoder().encode(validatedEntries)
                                            UserDefaults.standard.set(updatedData, forKey: "diaryEntries")
                                            UserDefaults.standard.synchronize()
                                            print("✅ [프로필 일기] 수정된 URL들 저장 완료")
                                        } catch {
                                            print("❌ [프로필 일기] URL 수정 저장 실패: \(error)")
                                        }
                                    }
                                    
                                    diaryEntries = validatedEntries.sorted { $0.date > $1.date }
                                    print("✅ [ProfileView] 일기 목록 로드 완료: \(validatedEntries.count)개")
                                    
                                    // 디버깅: 로드된 일기 내용 확인
                                    for (index, entry) in validatedEntries.enumerated() {
                                        print("   \(index + 1). \(entry.title) - ID: \(entry.id)")
                                        print("      날짜: \(entry.date)")
                                        print("      이미지: \(entry.imageURL.isEmpty ? "없음" : "있음(\(entry.imageURL.prefix(50))...)")")
                                        
                                        // 이미지 파일 존재 확인
                                        if !entry.imageURL.isEmpty, let url = URL(string: entry.imageURL) {
                                            let exists = FileManager.default.fileExists(atPath: url.path)
                                            print("      파일 존재: \(exists ? "✅" : "❌")")
                                        }
                                    }
                                } else {
                                    print("📝 [ProfileView] 저장된 일기가 없습니다")
                                    diaryEntries = []
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
                                        
                                        // ✅ 수정: 사용자가 직접 변경한 이름을 최우선으로 저장
                                        UserDefaults.standard.set(editUserName, forKey: "userEditedName") // 새로운 키 추가
                                        UserDefaults.standard.set(editUserName, forKey: "userName")
                                        UserDefaults.standard.set(editUserName, forKey: "currentUserName")

                                        // ⚠️ appleUserName은 Apple 원본 정보이므로 덮어쓰지 않음
                                        // UserDefaults.standard.set(editUserName, forKey: "appleUserName") // 제거

                                        UserDefaults.standard.synchronize()

                                        print("✅ [프로필 편집] 사용자 이름 저장 완료: \(editUserName)")
                                        print("🔍 [프로필 편집] 저장된 키들:")
                                        print("   - userEditedName: \(UserDefaults.standard.string(forKey: "userEditedName") ?? "없음")")
                                        print("   - userName: \(UserDefaults.standard.string(forKey: "userName") ?? "없음")")
                                        print("   - currentUserName: \(UserDefaults.standard.string(forKey: "currentUserName") ?? "없음")")
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
                // 사용자 이름 (연필 아이콘 제거)
                Text(userName)
                    .font(.title)
                    .bold()
                    .foregroundColor(.whiffPrimaryText)
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
                
            }
            .padding(.horizontal)
            
            if projectStore.projects.isEmpty {
                // 빈 상태 뷰
                VStack(spacing: 12) {
                    Image(systemName: "drop")
                        .font(.largeTitle)
                        .foregroundColor(.whiffSecondaryText2.opacity(0.6))
                    Text("아직 추천받은 향수가 없어요")
                        .font(.subheadline)
                        .foregroundColor(.whiffSecondaryText2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.whiffSectionBackground)
                .cornerRadius(16)
                .padding(.horizontal)
            } else {
                // 프로젝트 목록
                VStack(spacing: 16) {
                    ForEach(projectStore.projects.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { project in
                        ProjectPreviewCard(project: project)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - 프로젝트 미리보기 카드 (더보기 기능 포함)
struct ProjectPreviewCard: View {
    let project: Project
    @State private var isExpanded = false
    
    private let maxPreviewCount = 3
    
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
                
                // 전체보기 버튼
                NavigationLink(destination: ProjectDetailView(project: project)) {
                    HStack(spacing: 4) {
                        Text("전체보기")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .foregroundColor(.whiffPrimary)
                }
            }
            
            // 향수 미리보기 목록
            VStack(spacing: 12) {
                // 처음 3개 향수 표시
                ForEach(Array(project.recommendations.prefix(isExpanded ? project.recommendations.count : maxPreviewCount).enumerated()), id: \.offset) { index, perfume in
                    PerfumePreviewRow(perfume: perfume)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // 더보기 버튼 (4개 이상일 때만 표시)
                if project.recommendations.count > maxPreviewCount {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isExpanded {
                                Text("접기")
                                Image(systemName: "chevron.up")
                            } else {
                                Text("더보기 (+\(project.recommendations.count - maxPreviewCount))")
                                Image(systemName: "chevron.down")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.whiffPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.whiffPrimary.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle()) // 터치 영역 명확히 지정
                }
            }
        }
        .padding()
        .background(Color.whiffSectionBackground)
        .cornerRadius(16)
    }
}

// MARK: - 향수 미리보기 행
struct PerfumePreviewRow: View {
    let perfume: Perfume
    
    var body: some View {
        HStack(spacing: 12) {
            // 향수 이미지
            AsyncImage(url: URL(string: perfume.imageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.whiffMainBackground)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.whiffSecondaryText2)
                    )
            }
            .frame(width: 50, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 향수 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(perfume.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.whiffPrimaryText)
                    .lineLimit(1)
                
                Text(perfume.brand)
                    .font(.caption)
                    .foregroundColor(.whiffPrimary)
                    .lineLimit(1)
                
                // 매치 점수 (있는 경우)
                if perfume.similarity > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.caption2)
                        
                        Text("매치도 \(String(format: "%.0f", perfume.similarity * 100))%")
                            .font(.caption2)
                            .foregroundColor(.pink)
                    }
                }
            }
            
            Spacer()
            
            // 가격 부분 제거됨 - 이제 가격이 표시되지 않습니다
        }
        .padding(.vertical, 4)
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
                            NavigationLink(destination: DiaryEntryDetailView(entry: entry)) {
                                HStack(spacing: 12) {
                                    // 이미지 또는 기분 이모지 표시
                                    if !entry.imageURL.isEmpty {
                                        DiaryLocalImageView(imageUrl: entry.imageURL)
                                    } else {
                                        // 이미지가 없을 때 기분 이모지 표시
                                        Text(entry.mood)
                                            .font(.title2)
                                            .frame(width: 60, height: 60)
                                            .background(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.whiffPrimary.opacity(0.1), Color.whiffGradientStart.opacity(0.3)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .clipShape(Circle())
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        // 제목 표시 개선
                                        Text(entry.title.isEmpty ? "제목 없음" : entry.title)
                                            .font(.headline)
                                            .foregroundColor(.whiffPrimaryText)
                                            .lineLimit(1)
                                        
                                        // 내용 미리보기
                                        Text(entry.content.isEmpty ? "내용 없음" : entry.content)
                                            .font(.subheadline)
                                            .foregroundColor(.whiffSecondaryText2)
                                            .lineLimit(2)
                                        
                                        // 날짜와 이미지 표시 인디케이터
                                        HStack(spacing: 8) {
                                            Text(formatDate(entry.date))
                                                .font(.caption)
                                                .foregroundColor(.whiffSecondaryText2)
                                            
                                            if !entry.imageURL.isEmpty {
                                                Image(systemName: "photo")
                                                    .font(.caption)
                                                    .foregroundColor(.whiffPrimary)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // 타입 아이콘
                                    VStack(spacing: 4) {
                                        if entry.title.contains("시향 일기") {
                                            Image(systemName: "drop.fill")
                                                .font(.caption)
                                                .foregroundColor(.whiffPrimary)
                                        }
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.whiffSecondaryText2)
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .onDelete(perform: deleteDiary)
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
            .onAppear {
                debugUserDefaults()
                loadDiaryEntries()
                
                // NotificationCenter 옵저버 추가
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("DiaryUpdated"),
                    object: nil,
                    queue: .main
                ) { _ in
                    print("📢 [DiaryManagementView] 일기 업데이트 알림 수신")
                    loadDiaryEntries()
                }
            }
            .onDisappear {
                // 옵저버 제거
                NotificationCenter.default.removeObserver(self, name: Notification.Name("DiaryUpdated"), object: nil)
            }
        }
    }
    
    // MARK: - Private Functions
    
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
    
    private func deleteDiary(at offsets: IndexSet) {
        let sortedEntries = diaryEntries.sorted { $0.date > $1.date }
        
        for index in offsets {
            if let diaryIndex = diaryEntries.firstIndex(where: { $0.id == sortedEntries[index].id }) {
                let deletedDiary = diaryEntries[diaryIndex]
                print("🗑️ [일기 삭제] 삭제할 일기 ID: \(deletedDiary.id)")
                
                // 1. 프로필 일기에서 삭제
                diaryEntries.remove(at: diaryIndex)
                print("✅ [일기 삭제] 프로필 일기에서 삭제 완료")
                
                // 2. 시향일기(localDiaries)에서도 동일한 ID 삭제
                if let localDiariesData = UserDefaults.standard.data(forKey: "localDiaries") {
                    do {
                        // JSON을 Dictionary 배열로 디코딩
                        if let jsonArray = try JSONSerialization.jsonObject(with: localDiariesData, options: []) as? [[String: Any]] {
                            // 삭제할 ID와 일치하지 않는 항목들만 필터링
                            let filteredArray = jsonArray.filter { dict in
                                if let id = dict["id"] as? String {
                                    return id != deletedDiary.id
                                }
                                return true
                            }
                            
                            // 다시 JSON 데이터로 변환
                            let updatedData = try JSONSerialization.data(withJSONObject: filteredArray, options: [])
                            UserDefaults.standard.set(updatedData, forKey: "localDiaries")
                            UserDefaults.standard.synchronize()
                            
                            if filteredArray.count < jsonArray.count {
                                print("✅ [일기 삭제] 시향일기에서도 삭제 완료")
                            } else {
                                print("ℹ️ [일기 삭제] 시향일기에서 해당 ID를 찾지 못함")
                            }
                        }
                    } catch {
                        print("❌ [일기 삭제] 시향일기 처리 실패: \(error)")
                    }
                } else {
                    print("ℹ️ [일기 삭제] 시향일기 데이터가 없음")
                }
            }
        }
        
        // 3. 프로필 일기 데이터 저장
        saveDiaryEntries()
        
        // 4. 시향일기 뷰모델에 삭제 알림 전송
        NotificationCenter.default.post(name: Notification.Name("ScentDiaryDeleted"), object: nil)
        
        // 5. 다른 뷰에 알림 전송
        NotificationCenter.default.post(name: Notification.Name("DiaryUpdated"), object: nil)
        print("📢 [DiaryManagementView] 일기 삭제 알림 전송")
    }
    
    private func loadDiaryEntries() {
        print("🔄 [DiaryManagementView] 일기 목록 로드 시작...")
        
        // UserDefaults에서 일기 데이터 불러오기
        if let data = UserDefaults.standard.data(forKey: "diaryEntries"),
           let entries = try? JSONDecoder().decode([DiaryEntry].self, from: data) {
            
            DispatchQueue.main.async {
                self.diaryEntries = entries.sorted { $0.date > $1.date }
                print("✅ [DiaryManagementView] 일기 목록 로드 완료: \(entries.count)개")
                
                // 디버깅: 로드된 일기 내용 확인 (이미지 URL 포함)
                for (index, entry) in entries.enumerated() {
                    print("   \(index + 1). \(entry.title)")
                    print("      내용: \(entry.content.prefix(50))...")
                    print("      날짜: \(entry.date)")
                    print("      기분: \(entry.mood)")
                    print("      이미지: \(entry.imageURL.isEmpty ? "없음" : "있음(\(entry.imageURL.prefix(50))...)")")
                }
            }
        } else {
            print("📝 [DiaryManagementView] 저장된 일기가 없습니다")
            DispatchQueue.main.async {
                self.diaryEntries = []
            }
        }
    }
    
    private func saveDiaryEntries() {
        do {
            let data = try JSONEncoder().encode(diaryEntries)
            UserDefaults.standard.set(data, forKey: "diaryEntries")
            UserDefaults.standard.synchronize()
            print("✅ [DiaryManagementView] 일기 데이터 저장 완료: \(diaryEntries.count)개")
        } catch {
            print("❌ [DiaryManagementView] 일기 데이터 저장 실패: \(error)")
        }
    }
    
    private func debugUserDefaults() {
        print("🔍 [디버깅] UserDefaults 확인...")
        
        if let data = UserDefaults.standard.data(forKey: "diaryEntries") {
            print("✅ UserDefaults에 데이터 존재: \(data.count) bytes")
            
            if let entries = try? JSONDecoder().decode([DiaryEntry].self, from: data) {
                print("📋 디코딩 성공: \(entries.count)개 일기")
                for (index, entry) in entries.enumerated() {
                    print("   \(index): \(entry.title) - \(entry.content.prefix(20))...")
                    print("      이미지 URL: \(entry.imageURL)")
                }
            } else {
                print("❌ 디코딩 실패")
            }
        } else {
            print("❌ UserDefaults에 데이터 없음")
        }
    }
    
    // MARK: - DiaryLocalImageView (DiaryManagementView 전용)
    private struct DiaryLocalImageView: View {
        let imageUrl: String
        @State private var image: UIImage?
        @State private var isLoading = true
        
        var body: some View {
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if isLoading {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.6)
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .font(.caption)
                        )
                }
            }
            .onAppear {
                loadLocalImage()
            }
        }
        
        private func loadLocalImage() {
            print("📸 [DiaryLocalImageView] 이미지 로딩 시작: \(imageUrl)")
            
            guard let url = URL(string: imageUrl) else {
                print("❌ [DiaryLocalImageView] 잘못된 URL: \(imageUrl)")
                isLoading = false
                return
            }
            
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    let data = try Data(contentsOf: url)
                    if let uiImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.image = uiImage
                            self.isLoading = false
                            print("✅ [DiaryLocalImageView] 이미지 로딩 성공")
                        }
                    } else {
                        throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "이미지 데이터 변환 실패"])
                    }
                } catch {
                    print("❌ [DiaryLocalImageView] 이미지 로딩 실패: \(error)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

struct DiaryEntryDetailView: View {
    let entry: DiaryEntry
    @Environment(\.presentationMode) var presentationMode
    @State private var showingActionSheet = false
    @State private var showingReportSheet = false
    @State private var reportReason = ""
    @State private var showReportSuccess = false
    @State private var showReportError = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더 영역
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(entry.mood)
                            .font(.system(size: 50))
                            .frame(width: 70, height: 70)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.whiffPrimary.opacity(0.1), Color.whiffGradientStart.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title.isEmpty ? "제목 없음" : entry.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.whiffPrimaryText)
                            
                            Text(formatFullDate(entry.date))
                                .font(.subheadline)
                                .foregroundColor(.whiffSecondaryText2)
                            
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
                        
                        // 점 세 개 버튼 (신고 기능)
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
                .padding(.horizontal)
                
                Divider()
                
                // 첨부 이미지 섹션 (수정된 부분)
                if !entry.imageURL.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("첨부 이미지")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.whiffPrimaryText)
                            .padding(.horizontal)
                        
                        DetailImageView(imageUrl: entry.imageURL)
                            .padding(.horizontal)
                    }
                    
                    Divider()
                }
                
                // 일기 내용
                VStack(alignment: .leading, spacing: 12) {
                    Text("일기 내용")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.whiffPrimaryText)
                    
                    Text(entry.content.isEmpty ? "내용이 없습니다." : entry.content)
                        .font(.body)
                        .foregroundColor(.whiffPrimaryText)
                        .lineSpacing(4)
                }
                .padding(.horizontal)
                
                // 작성 정보
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "calendar", title: "작성 시간", content: formatFullDate(entry.date))
                    InfoRow(icon: "heart", title: "기분", content: "\(entry.mood) 기분")
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.whiffSectionBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 하단 여백
                Color.clear.frame(height: 50)
            }
        }
        .background(Color.whiffMainBackground)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReportSheet) {
            DiaryReportView(
                diaryId: entry.id,
                reportReason: $reportReason,
                showReportSuccess: $showReportSuccess,
                showReportError: $showReportError
            )
        }
        .alert("신고 완료", isPresented: $showReportSuccess) {
            Button("확인") { }
        } message: {
            Text("신고가 접수되었습니다. 검토 후 처리하겠습니다.")
        }
        .alert("신고 실패", isPresented: $showReportError) {
            Button("확인") { }
        } message: {
            Text("신고 처리 중 오류가 발생했습니다. 다시 시도해주세요.")
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: date)
    }
    
    // MARK: - DetailImageView (상세 화면용 이미지 뷰)
    private struct DetailImageView: View {
        let imageUrl: String
        @State private var image: UIImage?
        @State private var isLoading = true
        @State private var hasError = false
        
        var body: some View {
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                } else if isLoading {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("이미지 로딩 중...")
                                    .font(.caption)
                                    .foregroundColor(.whiffSecondaryText2)
                            }
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .cornerRadius(12)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.whiffSecondaryText2)
                                Text("이미지를 불러올 수 없습니다")
                                    .font(.caption)
                                    .foregroundColor(.whiffSecondaryText2)
                            }
                        )
                }
            }
            .onAppear {
                loadDetailImage()
            }
        }
        
        private func loadDetailImage() {
            print("📸 [DetailImageView] 이미지 로딩 시작: \(imageUrl)")
            
            guard let url = URL(string: imageUrl) else {
                print("❌ [DetailImageView] 잘못된 URL: \(imageUrl)")
                hasError = true
                isLoading = false
                return
            }
            
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    let data = try Data(contentsOf: url)
                    if let uiImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.image = uiImage
                            self.isLoading = false
                            self.hasError = false
                            print("✅ [DetailImageView] 이미지 로딩 성공")
                        }
                    } else {
                        throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "이미지 데이터 변환 실패"])
                    }
                } catch {
                    print("❌ [DetailImageView] 이미지 로딩 실패: \(error)")
                    DispatchQueue.main.async {
                        self.hasError = true
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

// MARK: - 신고 뷰
struct DiaryReportView: View {
    let diaryId: String
    @Binding var reportReason: String
    @Binding var showReportSuccess: Bool
    @Binding var showReportError: Bool
    @Environment(\.presentationMode) var presentationMode
    
    private let reportOptions = [
        "부적절한 내용",
        "스팸 또는 광고",
        "허위 정보",
        "기타"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("신고 사유를 선택해주세요")
                    .font(.headline)
                    .foregroundColor(.whiffPrimaryText)
                    .padding(.top)
                
                VStack(spacing: 12) {
                    ForEach(reportOptions, id: \.self) { option in
                        Button(action: {
                            reportReason = option
                        }) {
                            HStack {
                                Image(systemName: reportReason == option ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(reportReason == option ? .whiffPrimary : .whiffSecondaryText2)
                                
                                Text(option)
                                    .font(.body)
                                    .foregroundColor(.whiffPrimaryText)
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.whiffSectionBackground)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button(action: {
                    submitReport()
                }) {
                    Text("신고하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(reportReason.isEmpty ? Color.gray : Color.red)
                        .cornerRadius(12)
                }
                .disabled(reportReason.isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color.whiffMainBackground)
            .navigationTitle("일기 신고")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func submitReport() {
        // 신고 API 호출 (현재는 시뮬레이션)
        guard !reportReason.isEmpty else { return }
        
        // 실제 구현시에는 여기서 API 호출
        print("📝 [신고] 일기 ID: \(diaryId), 사유: \(reportReason)")
        
        // 시뮬레이션: 성공적으로 신고 처리
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            presentationMode.wrappedValue.dismiss()
            showReportSuccess = true
        }
        
        // 실제 API 구현 예시:
        /*
        Task {
            do {
                // API 호출
                try await APIClient.shared.reportDiary(diaryId: diaryId, reason: reportReason)
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                    showReportSuccess = true
                }
            } catch {
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                    showReportError = true
                }
            }
        }
        */
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
                        Text("버전 \(Bundle.appVersion)")  // ← 동적으로 변경
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
            OnboardingView(isFirstLaunch: $showingOnboarding)
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

// MARK: - 공지사항 섹션 (개별 클릭 기능 추가)
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
                // 최신 공지사항 3개만 표시 - 개별 클릭 가능
                VStack(spacing: 0) {
                    ForEach(Array(announcementManager.announcements.prefix(3).enumerated()), id: \.element.id) { index, announcement in
                        
                        // 개별 공지사항을 클릭할 수 있도록 NavigationLink로 감싸기
                        NavigationLink(destination: AnnouncementDetailView(announcement: announcement)) {
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
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.whiffPrimary)
                                            .cornerRadius(8)
                                        
                                        Text(announcement.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundColor(.whiffSecondaryText2)
                                        
                                        Spacer()
                                    }
                                }
                                
                                // 화살표 아이콘 추가
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.whiffSecondaryText2)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.whiffSectionBackground)
                            .contentShape(Rectangle()) // 전체 영역 클릭 가능하게 만들기
                        }
                        .buttonStyle(PlainButtonStyle()) // 기본 버튼 스타일 제거
                        
                        // 구분선 (마지막 항목이 아닐 때만)
                        if index < min(2, announcementManager.announcements.count - 1) {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .background(Color.whiffSectionBackground)
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
    }
    
    // 새로운 공지사항 여부 확인
    private var hasNewAnnouncements: Bool {
        // 여기서는 간단히 최근 7일 이내의 공지사항이 있으면 true 반환
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return announcementManager.announcements.contains { $0.date > sevenDaysAgo }
    }
    // ProfileView.swift 파일 끝에 (마지막 } 바로 앞에) 다음 코드를 추가하세요

    // MARK: - Profile용 로컬 이미지 뷰
    struct ProfileLocalImageView: View {
        let imageUrl: String
        @State private var image: UIImage?
        @State private var isLoading = true
        
        var body: some View {
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                } else if isLoading {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.6)
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                                .font(.caption)
                        )
                }
            }
            .onAppear {
                loadLocalImage()
            }
        }
        
        private func loadLocalImage() {
            guard let url = URL(string: imageUrl) else {
                isLoading = false
                return
            }
            
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    let data = try Data(contentsOf: url)
                    if let uiImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.image = uiImage
                            self.isLoading = false
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.isLoading = false
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

