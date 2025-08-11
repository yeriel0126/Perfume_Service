import SwiftUI
import PhotosUI

// MARK: - Views
struct NewScentDiaryView: View {
   @StateObject private var viewModel = NewScentDiaryViewModel()
   @StateObject private var scentDiaryViewModel = ScentDiaryViewModel()
   @EnvironmentObject var authViewModel: AuthViewModel
   @Environment(\.dismiss) private var dismiss
   @Binding var selectedTab: Int
   @State private var showingPerfumePicker = false
   @State private var showingAlert = false
   @State private var selectedItem: PhotosPickerItem? = nil
   @State private var selectedImage: UIImage? = nil
   @State private var isLoadingImage = false
   @State private var showingPerfumeMentions = false
   @State private var searchText = ""
   @State private var availablePerfumes: [Perfume] = []
   @State private var hashtags: Set<String> = []
   @State private var selectedPerfumeName: String = "" // 직접 선택한 향수명
   @FocusState private var isTextEditorFocused: Bool
   @State private var showingImageEditor = false
   @State private var originalImage: UIImage? = nil
   @State private var customTagText = ""
   @State private var manualTags: Set<String> = []
   
   // 현재 사용자 정보
   private var currentUser: UserData? {
       authViewModel.user?.data
   }
   
   private var currentUserId: String {
       if let user = currentUser {
           return user.uid
       }
       // 로그인하지 않은 경우 기본값
       return UserDefaults.standard.string(forKey: "currentUserId") ?? UUID().uuidString
   }
   
   private var currentUserName: String {
       if let user = currentUser, let name = user.name {
           return name
       }
       // 로그인하지 않은 경우 기본값
       return UserDefaults.standard.string(forKey: "currentUserName") ?? "사용자"
   }
   
   private var currentUserProfileImage: String {
       if let user = currentUser, let picture = user.picture {
           return picture
       }
       // 로그인하지 않은 경우 기본값
       return UserDefaults.standard.string(forKey: "currentUserProfileImage") ?? ""
   }
   
   var body: some View {
       NavigationView {
           VStack(spacing: 0) {
               // 상단 네비게이션 바
               CustomNavigationBar()
               
               ScrollView {
                   VStack(spacing: 0) {
                       // 사진 선택 영역 (상단 고정)
                       PhotoSelectionArea()
                       
                       // 구분선
                       Divider()
                           .padding(.vertical, 8)
                       
                       // 텍스트 입력 영역
                       PostContentArea()
                       
                       // 설정 영역
                       SettingsArea()
                       
                       // 하단 여백
                       Color.clear.frame(height: 100)
                   }
               }
               
               // 하단 고정 저장 버튼
               BottomSaveButton()
           }
           .background(Color.whiffMainBackground)
           .navigationBarHidden(true)
           .onChange(of: selectedItem) { _, newItem in
               Task {
                   await loadImage(from: newItem)
               }
           }
           .alert("오류", isPresented: $scentDiaryViewModel.showError) {
               Button("확인") {
                   scentDiaryViewModel.clearError()
               }
           } message: {
               Text(scentDiaryViewModel.error?.localizedDescription ?? "알 수 없는 오류가 발생했습니다.")
           }
           .sheet(isPresented: $showingImageEditor) {
               if let originalImage = originalImage {
                   ImageEditorView(originalImage: originalImage) { editedImage in
                       selectedImage = editedImage
                       showingImageEditor = false
                   } onCancel: {
                       showingImageEditor = false
                   }
               }
           }
           .sheet(isPresented: $showingPerfumeMentions) {
               PerfumeSearchView(
                   availablePerfumes: availablePerfumes,
                   onPerfumeSelected: { perfume in
                       selectedPerfumeName = perfume.name
                       print("✅ [향수 선택] 선택된 향수: \(perfume.name)")
                       showingPerfumeMentions = false
                   }
               )
           }
       }
       .task {
           await loadAvailablePerfumes()
       }
   }
   
   // MARK: - 하위 뷰들
   
   @ViewBuilder
   private func CustomNavigationBar() -> some View {
       HStack {
           Button("취소") {
               dismiss()
           }
           .foregroundColor(.whiffPrimaryText)
           
           Spacer()
           
           Text("새 게시물")
               .font(.headline)
               .fontWeight(.semibold)
               .foregroundColor(.whiffPrimaryText)
           
           Spacer()
       }
       .padding(.horizontal)
       .padding(.vertical, 12)
       .background(Color.whiffMainBackground)
       .overlay(
           Rectangle()
               .frame(height: 0.5)
               .foregroundColor(Color.whiffSecondaryText2.opacity(0.3)),
           alignment: .bottom
       )
   }
   
   @ViewBuilder
   private func PhotoSelectionArea() -> some View {
       VStack(spacing: 0) {
           if let selectedImage = selectedImage {
               // 선택된 이미지 표시
               Image(uiImage: selectedImage)
                   .resizable()
                   .aspectRatio(1, contentMode: .fill)
                   .frame(maxWidth: .infinity)
                   .frame(height: UIScreen.main.bounds.width) // 정사각형
                   .clipped()
                   .overlay(
                       // 이미지 편집 버튼
                       VStack {
                           HStack {
                               Spacer()
                               Button(action: {
                                   originalImage = selectedImage
                                   showingImageEditor = true
                               }) {
                                   Image(systemName: "crop")
                                       .font(.title2)
                                       .foregroundColor(.whiffWhiteText)
                                       .padding(8)
                                       .background(Circle().fill(Color.whiffPrimaryText.opacity(0.6)))
                               }
                               .padding(.top, 12)
                               .padding(.trailing, 12)
                           }
                           
                           Spacer()
                           
                           HStack {
                               Spacer()
                               PhotosPicker(
                                   selection: $selectedItem,
                                   matching: .images,
                                   photoLibrary: .shared()
                               ) {
                                   Image(systemName: "photo")
                                       .font(.title2)
                                       .foregroundColor(.whiffWhiteText)
                                       .padding(8)
                                       .background(Circle().fill(Color.whiffPrimaryText.opacity(0.6)))
                               }
                               .padding(.bottom, 12)
                               .padding(.trailing, 12)
                           }
                       }
                   )
           } else if isLoadingImage {
               // 로딩 상태
               VStack(spacing: 16) {
                   ProgressView()
                       .progressViewStyle(CircularProgressViewStyle())
                       .scaleEffect(1.2)
                   
                   Text("이미지 로딩 중...")
                       .font(.subheadline)
                       .foregroundColor(.whiffSecondaryText2)
               }
               .frame(height: 200)
               .frame(maxWidth: .infinity)
               .background(Color.whiffSectionBackground)
           } else {
               // 사진 선택 프롬프트
               PhotosPicker(
                   selection: $selectedItem,
                   matching: .images,
                   photoLibrary: .shared()
               ) {
                   VStack(spacing: 16) {
                       Image(systemName: "camera.fill")
                           .font(.system(size: 40))
                           .foregroundColor(.whiffPrimary)
                       
                       Text("사진 추가")
                           .font(.headline)
                           .foregroundColor(.whiffPrimaryText)
                       
                       Text("터치하여 갤러리에서 사진을 선택하세요")
                           .font(.caption)
                           .foregroundColor(.whiffSecondaryText2)
                           .multilineTextAlignment(.center)
                   }
                   .frame(height: 200)
                   .frame(maxWidth: .infinity)
                   .background(Color.whiffSectionBackground)
                   .clipShape(RoundedRectangle(cornerRadius: 12))
               }
               .padding(.horizontal)
           }
       }
   }
   
   @ViewBuilder
   private func PostContentArea() -> some View {
       VStack(spacing: 12) {
           // 사용자 헤더
           HStack(spacing: 12) {
               if !currentUserProfileImage.isEmpty {
                   AsyncImage(url: URL(string: currentUserProfileImage)) { image in
                       image
                           .resizable()
                           .aspectRatio(1, contentMode: .fill)
                           .frame(width: 40, height: 40)
                           .clipShape(Circle())
                   } placeholder: {
                       Image(systemName: "person.circle.fill")
                           .font(.title)
                           .foregroundColor(.whiffSecondaryText2)
                           .frame(width: 40, height: 40)
                   }
               } else {
                   Image(systemName: "person.circle.fill")
                       .font(.title)
                       .foregroundColor(.whiffSecondaryText2)
                       .frame(width: 40, height: 40)
               }
               
               VStack(alignment: .leading, spacing: 2) {
                   Text(currentUserName)
                       .font(.subheadline)
                       .fontWeight(.semibold)
                       .foregroundColor(.whiffPrimaryText)
                   
                   Text("지금")
                       .font(.caption)
                       .foregroundColor(.whiffSecondaryText2)
               }
               
               Spacer()
           }
           .padding(.horizontal)
           
           // 텍스트 입력 영역
           VStack(alignment: .leading, spacing: 8) {
               Text("오늘의 시향 일기")
                   .font(.caption)
                   .foregroundColor(.whiffSecondaryText2)
                   .padding(.horizontal)
               
               ZStack(alignment: .topLeading) {
                   // 배경 박스
                   RoundedRectangle(cornerRadius: 8)
                       .fill(Color.whiffSectionBackground)
                       .overlay(
                           RoundedRectangle(cornerRadius: 8)
                               .stroke(Color.whiffPrimary.opacity(0.5), lineWidth: 1)
                       )
                       .frame(minHeight: 120)
                   
                   // TextEditor (완전 투명 처리)
                   TextEditor(text: $viewModel.content)
                       .padding(12)
                       .background(Color.clear)
                       .scrollContentBackground(.hidden)  // iOS 16+ 전용 - 스크롤 배경 숨김
                       .foregroundColor(.whiffPrimaryText)
                       .font(.body)
                       .frame(minHeight: 120)
                       .focused($isTextEditorFocused)
                       .onAppear {
                           // iOS 버전별 배경 제거
                           UITextView.appearance().backgroundColor = UIColor.clear
                       }
                       .onChange(of: viewModel.content) { _, _ in
                           detectHashtags()
                       }
                   
                   // Placeholder는 그대로 유지...
               }
               .padding(.horizontal)
           }
           // 해시태그 표시
           if !hashtags.isEmpty {
               ScrollView(.horizontal, showsIndicators: false) {
                   HStack(spacing: 8) {
                       // 해시태그 표시
                       ForEach(Array(hashtags), id: \.self) { tag in
                           HStack(spacing: 4) {
                               Image(systemName: "number")
                                   .font(.caption)
                               Text(tag)
                                   .font(.caption)
                           }
                           .padding(.horizontal, 8)
                           .padding(.vertical, 4)
                           .background(Color.whiffPrimary.opacity(0.1))
                           .foregroundColor(.whiffPrimary)
                           .clipShape(Capsule())
                       }
                   }
                   .padding(.horizontal)
               }
           }
           
           // 향수 선택 영역
           VStack(alignment: .leading, spacing: 8) {
               Text("향수 선택")
                   .font(.subheadline)
                   .fontWeight(.medium)
                   .foregroundColor(.whiffPrimaryText)
               
               if selectedPerfumeName.isEmpty {
                   Button(action: {
                       showingPerfumeMentions = true
                   }) {
                       HStack(spacing: 8) {
                           Image(systemName: "plus.circle")
                           Text("향수 선택하기")
                       }
                       .font(.subheadline)
                       .foregroundColor(.whiffPrimary)
                       .padding(.horizontal, 16)
                       .padding(.vertical, 12)
                       .background(Color.whiffPrimary.opacity(0.1))
                       .clipShape(RoundedRectangle(cornerRadius: 8))
                   }
               } else {
                   HStack {
                       HStack(spacing: 8) {
                           Image(systemName: "drop.fill")
                               .foregroundColor(.whiffPrimary)
                           Text(selectedPerfumeName)
                               .font(.subheadline)
                               .foregroundColor(.whiffPrimaryText)
                       }
                       .padding(.horizontal, 12)
                       .padding(.vertical, 8)
                       .background(Color.whiffPrimary.opacity(0.1))
                       .clipShape(Capsule())
                       
                       Spacer()
                       
                       Button(action: {
                           showingPerfumeMentions = true
                       }) {
                           Text("변경")
                               .font(.caption)
                               .foregroundColor(.whiffPrimary)
                       }
                       
                       Button(action: {
                           selectedPerfumeName = ""
                       }) {
                           Image(systemName: "xmark.circle.fill")
                               .foregroundColor(.whiffSecondaryText2)
                       }
                   }
               }
           }
           .padding(.horizontal)
           
           // 사용자 직접 입력 섹션
           VStack(alignment: .leading, spacing: 12) {
               Text("태그")
                   .font(.caption)
                   .foregroundColor(.whiffSecondaryText2)
                   .padding(.horizontal)
               
               // 태그 입력 필드
               HStack(spacing: 12) {
                   TextField("태그 입력 (예: 상쾌한, 달콤한)", text: $customTagText)
                       .textFieldStyle(CustomWhiffTextFieldStyle())
                       .onSubmit {
                           addCustomTag()
                       }
                   
                   Button("추가") {
                       addCustomTag()
                   }
                   .font(.subheadline)
                   .fontWeight(.medium)
                   .foregroundColor(.whiffWhiteText)
                   .padding(.horizontal, 16)
                   .padding(.vertical, 12)
                   .background(customTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.whiffSecondaryText2 : Color.whiffPrimary)
                   .cornerRadius(8)
                   .disabled(customTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
               }
               .padding(.horizontal)
               
               // 사용자가 추가한 태그들
               if !manualTags.isEmpty {
                   LazyVGrid(columns: [
                       GridItem(.adaptive(minimum: 80))
                   ], spacing: 8) {
                       ForEach(Array(manualTags), id: \.self) { tag in
                           Button(action: {
                               removeManualTag(tag)
                           }) {
                               HStack(spacing: 4) {
                                   Text(tag)
                                       .font(.caption)
                                       .fontWeight(.medium)
                                   Image(systemName: "xmark.circle.fill")
                                       .font(.caption)
                               }
                               .padding(.horizontal, 12)
                               .padding(.vertical, 8)
                               .background(Color.whiffPrimary)
                               .foregroundColor(.whiffWhiteText)
                               .clipShape(Capsule())
                           }
                           .buttonStyle(PlainButtonStyle())
                       }
                   }
                   .padding(.horizontal)
               }
           }
           
           // 선택된 모든 태그 요약
           if !manualTags.isEmpty {
               VStack(alignment: .leading, spacing: 8) {
                   HStack {
                       Image(systemName: "checkmark.circle")
                           .foregroundColor(.whiffPrimary)
                           .font(.caption)
                       Text("선택된 태그 (\(manualTags.count)개)")
                           .font(.caption)
                           .foregroundColor(.whiffPrimary)
                           .fontWeight(.medium)
                       
                       Spacer()
                   }
                   .padding(.horizontal)
                   
                   Text(Array(manualTags).joined(separator: " • "))
                       .font(.caption)
                       .foregroundColor(.whiffSecondaryText2)
                       .padding(.horizontal)
               }
               .padding(.top, 8)
               .padding(.bottom, 4)
               .background(Color.whiffPrimary.opacity(0.05))
               .clipShape(RoundedRectangle(cornerRadius: 8))
               .padding(.horizontal)
           }
       }
       .padding(.vertical, 16)
       .background(
           RoundedRectangle(cornerRadius: 12)
               .fill(Color.whiffSectionBackground.opacity(0.5))
       )
       .padding(.horizontal)
   }
   
   @ViewBuilder
   private func SettingsArea() -> some View {
       VStack(spacing: 16) {
           // 공개 설정
           HStack {
               Image(systemName: viewModel.isPublic ? "globe" : "lock.fill")
                   .foregroundColor(viewModel.isPublic ? .whiffPrimary : .whiffSecondaryText2)
               
               VStack(alignment: .leading, spacing: 2) {
                   Text(viewModel.isPublic ? "공개 게시물" : "비공개 게시물")
                       .font(.subheadline)
                       .fontWeight(.medium)
                       .foregroundColor(.whiffPrimaryText)
                   
                   Text(viewModel.isPublic ? "다른 사용자들이 이 게시물을 볼 수 있습니다" : "나만 볼 수 있는 비공개 게시물입니다")
                       .font(.caption)
                       .foregroundColor(.whiffSecondaryText2)
               }
               
               Spacer()
               
               Toggle("", isOn: $viewModel.isPublic)
                   .labelsHidden()
                   .onChange(of: viewModel.isPublic) { oldValue, newValue in
                       print("🔐 [UI Toggle 변경] \(oldValue) → \(newValue)")
                       print("🔐 [UI Toggle 변경] 현재 상태: \(newValue ? "공개" : "비공개")")
                   }
           }
           .padding(.horizontal)
           .padding(.vertical, 12)
           .background(Color.whiffMainBackground)
           .clipShape(RoundedRectangle(cornerRadius: 12))
           .overlay(
               RoundedRectangle(cornerRadius: 12)
                   .stroke(Color.whiffSecondaryText2.opacity(0.3), lineWidth: 1)
           )
           .padding(.horizontal)
       }
       .padding(.vertical)
   }
   
   @ViewBuilder
   private func BottomSaveButton() -> some View {
       VStack(spacing: 0) {
           Divider()
           
           Button(action: saveDiary) {
               HStack {
                   if scentDiaryViewModel.isLoading {
                       ProgressView()
                           .progressViewStyle(CircularProgressViewStyle(tint: .whiffWhiteText))
                           .scaleEffect(0.8)
                   }
                   
                   Text(scentDiaryViewModel.isLoading ? "게시 중..." : "게시하기")
                       .font(.headline)
                       .fontWeight(.semibold)
                       .foregroundColor(.whiffWhiteText)
               }
               .frame(maxWidth: .infinity)
               .padding()
               .background(canSave ? Color.whiffPrimary : Color.whiffSecondaryText2)
               .clipShape(RoundedRectangle(cornerRadius: 12))
           }
           .disabled(!canSave || scentDiaryViewModel.isLoading)
           .padding(.horizontal)
           .padding(.vertical, 12)
           .background(Color.whiffMainBackground)
       }
   }
   
   // MARK: - 계산 속성
   
   private var canSave: Bool {
       let hasContent = !viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
       let hasImage = selectedImage != nil
       
       // 내용이나 이미지 중 하나만 있으면 게시 가능
       return hasContent || hasImage
   }
   
   // MARK: - 메서드
   
   private func addCustomTag() {
       let tag = customTagText.trimmingCharacters(in: .whitespacesAndNewlines)
       guard !tag.isEmpty && !manualTags.contains(tag) else {
           return
       }
       
       manualTags.insert(tag)
       customTagText = ""
   }
   
   private func removeManualTag(_ tag: String) {
       manualTags.remove(tag)
   }
   
   private func addHashtag() {
       // 간단한 해시태그 추가 기능 - 일반적인 태그들 제안
       let commonTags = ["일상", "데이터", "출근", "여행", "휴식", "기분좋은", "상쾌한", "따뜻한", "시원한", "우아한"]
       let availableTags = commonTags.filter { !hashtags.contains($0) }
       
       if let randomTag = availableTags.randomElement() {
           if viewModel.content.isEmpty {
               viewModel.content = "#\(randomTag) "
           } else {
               viewModel.content += " #\(randomTag)"
           }
           hashtags.insert(randomTag)
       }
   }
   
   private func loadAvailablePerfumes() async {
       do {
           let networkManager = NetworkManager.shared
           availablePerfumes = try await networkManager.fetchPerfumes()
       } catch {
           print("향수 로딩 실패: \(error)")
           availablePerfumes = PerfumeDataUtils.createSamplePerfumes()
       }
   }
   
   private func saveDiary() {
       // 해시태그 감지 업데이트
       detectHashtags()
       
       // 직접 선택한 향수명 사용, 없으면 기본값
       let perfumeName = selectedPerfumeName.isEmpty ? "향수 없음" : selectedPerfumeName
       
       // 사용자 직접 입력 태그와 해시태그만 사용
       let allTags = Array(manualTags) + Array(hashtags)
       
       // 현재 사용자 정보를 UserDefaults에 저장 (프로필 연동용)
       UserDefaults.standard.set(currentUserId, forKey: "currentUserId")
       UserDefaults.standard.set(currentUserName, forKey: "currentUserName")
       UserDefaults.standard.set(currentUserProfileImage, forKey: "currentUserProfileImage")
       UserDefaults.standard.synchronize()
       
       print("💾 [사용자 정보 저장] ID: \(currentUserId)")
       print("💾 [사용자 정보 저장] 이름: \(currentUserName)")
       print("💾 [사용자 정보 저장] 프로필: \(currentUserProfileImage)")
       print("🔐 [공개 설정 확인] viewModel.isPublic: \(viewModel.isPublic)")
       print("🔐 [공개 설정 확인] UI Toggle 상태: \(viewModel.isPublic ? "공개" : "비공개")")
       
       print("📝 [일기 내용 확인] 원본 내용: '\(viewModel.content)'")
       print("📝 [일기 내용 확인] 트림 후: '\(viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines))'")
       print("📝 [향수 확인] 선택한 향수명: '\(perfumeName)'")
       print("📝 [태그 확인] 모든 태그: \(allTags)")
       print("📝 [해시태그 확인] 해시태그: \(hashtags)")
       print("📝 [이미지 확인] 이미지 있음: \(selectedImage != nil)")
       
       if allTags.isEmpty {
           print("⚠️ [태그 경고] 태그가 하나도 없습니다!")
       }
       if viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
           print("⚠️ [내용 경고] 일기 내용이 비어있습니다!")
       }
       
       Task {
           let success = await scentDiaryViewModel.createDiary(
               userId: currentUserId,
               perfumeName: perfumeName,
               content: viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines),
               isPublic: viewModel.isPublic,
               emotionTags: allTags,
               selectedImage: selectedImage
           )
           
           if success {
               print("✅ [NewScentDiaryView] 시향 일기 게시 성공")
               
               // createDiary에서 이미 피드에 실시간 추가되므로 fetchDiaries 호출 불필요
               // await scentDiaryViewModel.fetchDiaries() // 제거
               
               // 탭 이동
               await MainActor.run {
                   selectedTab = 1 // 시향 일기 탭 (인덱스 1)
                   dismiss()
               }
           } else {
               print("❌ [NewScentDiaryView] 시향 일기 게시 실패")
           }
       }
   }
   
   private func detectHashtags() {
       // # 기호로 시작하는 해시태그 감지
       let hashPattern = "#([\\p{L}\\p{N}가-힣]+)"
       let hashRegex = try? NSRegularExpression(pattern: hashPattern, options: [])
       let range = NSRange(location: 0, length: viewModel.content.utf16.count)
       
       var newHashtags: Set<String> = []
       
       hashRegex?.enumerateMatches(in: viewModel.content, options: [], range: range) { match, _, _ in
           if let matchRange = match?.range(at: 1),
              let range = Range(matchRange, in: viewModel.content) {
               let hashtagText = String(viewModel.content[range]).trimmingCharacters(in: .whitespaces)
               if !hashtagText.isEmpty {
                   newHashtags.insert(hashtagText)
               }
           }
       }
       
       hashtags = newHashtags
   }
   
   private func loadImage(from item: PhotosPickerItem?) async {
       guard let item = item else {
           selectedImage = nil
           return
       }
       
       await MainActor.run {
           isLoadingImage = true
       }
       
       do {
           // Data 타입으로 로드한 후 UIImage로 변환
           if let data = try await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) {
               await MainActor.run {
                   originalImage = uiImage  // 원본 이미지 저장
                   selectedImage = uiImage  // 임시로 표시
                   isLoadingImage = false
                   showingImageEditor = true  // 편집 화면으로 이동
               }
               print("✅ [이미지 로딩] Data 변환으로 성공, 편집 화면 표시")
               return
           }
           
           // 데이터 로드 실패
           print("❌ [이미지 로딩] 데이터 로드 실패 또는 이미지 변환 실패")
           await MainActor.run {
               selectedImage = nil
               originalImage = nil
               isLoadingImage = false
           }
           
       } catch {
           print("❌ [이미지 로딩] 오류 발생: \(error.localizedDescription)")
           await MainActor.run {
               selectedImage = nil
               originalImage = nil
               isLoadingImage = false
           }
       }
   }
}

// MARK: - Perfume Search View
private struct PerfumeSearchView: View {
    let availablePerfumes: [Perfume]
    let onPerfumeSelected: (Perfume) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 로그인 화면과 동일한 그라데이션 배경 추가
                Color.whiffMainGradient
                    .ignoresSafeArea()
                
                // 기존 List 콘텐츠
                List {
                    ForEach(filteredPerfumes) { perfume in
                        Button(action: {
                            onPerfumeSelected(perfume)
                        }) {
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: perfume.imageURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.whiffSectionBackground)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.whiffSecondaryText2)
                                        )
                                }
                                .frame(width: 50, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(perfume.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.whiffPrimaryText)
                                        .lineLimit(2)
                                    
                                    Text(perfume.brand)
                                        .font(.caption)
                                        .foregroundColor(.whiffSecondaryText1)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color.clear) // 행 배경 투명
                    }
                }
                .background(Color.clear) // 리스트 배경 투명
                .scrollContentBackground(.hidden) // iOS 16+ 리스트 배경 숨김
            }
            .searchable(text: $searchText, prompt: "향수 검색")
            .navigationTitle("향수 언급")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(.whiffPrimaryText)
                }
            }
        }
    }
    
    private var filteredPerfumes: [Perfume] {
        if searchText.isEmpty {
            return Array(availablePerfumes.prefix(20)) // 처음 20개만 표시
        } else {
            return availablePerfumes.filter { perfume in
                perfume.name.localizedCaseInsensitiveContains(searchText) ||
                perfume.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

                                   struct NewScentDiaryView_Previews: PreviewProvider {
                                      static var previews: some View {
                                          NewScentDiaryView(selectedTab: .constant(0))
                                              .environmentObject(AuthViewModel())
                                      }
                                   }

// MARK: - Image Editor View
struct ImageEditorView: View {
    let originalImage: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0.0
    @State private var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    @State private var showingAspectRatios = false
    @State private var selectedAspectRatio: AspectRatio = .square
    
    enum AspectRatio: String, CaseIterable {
        case original = "원본"
        case square = "1:1"
        case portrait = "4:5"
        case landscape = "16:9"
        
        var ratio: CGFloat? {
            switch self {
            case .original: return nil
            case .square: return 1.0
            case .portrait: return 4.0/5.0
            case .landscape: return 16.0/9.0
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상단 네비게이션 - 수정된 부분
                HStack {
                    // 취소 버튼
                    Button(action: {
                        print("🔘 [ImageEditor] 취소 버튼 클릭")
                        DispatchQueue.main.async {
                            onCancel()
                        }
                    }) {
                        Text("취소")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.whiffPrimaryText)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("편집")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.whiffPrimaryText)
                    
                    Spacer()
                    
                    // 완료 버튼
                    Button(action: {
                        print("🔘 [ImageEditor] 완료 버튼 클릭")
                        DispatchQueue.main.async {
                            saveEditedImage()
                        }
                    }) {
                        Text("완료")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.whiffWhiteText)
                            .frame(width: 80, height: 36)
                            .background(Color.whiffPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.whiffMainBackground)
                .zIndex(100) // 최상위 레이어로 설정
                
                // 이미지 편집 영역 - 기존 CroppableImageView 사용하지 않고 직접 구현
                GeometryReader { geometry in
                    ZStack {
                        Color.whiffMainBackground
                        
                        // 이미지 직접 표시
                        Image(uiImage: originalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .rotationEffect(.degrees(rotation))
                            .gesture(
                                SimultaneousGesture(
                                    // 확대/축소 제스처
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = max(0.5, min(3.0, value))
                                        },
                                    
                                    // 드래그 제스처
                                    DragGesture()
                                        .onChanged { value in
                                            offset = value.translation
                                        }
                                )
                            )
                            .clipped()
                        
                        // 크롭 오버레이 (옵셔널 처리)
                        if let ratio = selectedAspectRatio.ratio {
                            SimpleCropOverlay(aspectRatio: ratio, availableSize: geometry.size)
                        }
                    }
                }
                
                // 하단 컨트롤
                VStack(spacing: 16) {
                    // 비율 선택 버튼들
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(AspectRatio.allCases, id: \.self) { ratio in
                                Button(action: {
                                    print("🔘 [ImageEditor] 비율 변경: \(ratio.rawValue)")
                                    selectedAspectRatio = ratio
                                    resetTransform()
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: getAspectRatioIcon(ratio))
                                            .font(.title2)
                                        Text(ratio.rawValue)
                                            .font(.caption)
                                    }
                                    .foregroundColor(selectedAspectRatio == ratio ? .whiffPrimary : .whiffPrimaryText)
                                    .frame(minWidth: 50, minHeight: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 조정 슬라이더들
                    VStack(spacing: 12) {
                        // 확대/축소
                        HStack {
                            Image(systemName: "minus.magnifyingglass")
                                .foregroundColor(.whiffSecondaryText2)
                            Slider(value: $scale, in: 0.5...3.0)
                                .accentColor(.whiffPrimary)
                            Image(systemName: "plus.magnifyingglass")
                                .foregroundColor(.whiffSecondaryText2)
                        }
                        
                        // 회전
                        HStack {
                            Image(systemName: "rotate.left")
                                .foregroundColor(.whiffSecondaryText2)
                            Slider(value: $rotation, in: -180...180)
                                .accentColor(.whiffPrimary)
                            Image(systemName: "rotate.right")
                                .foregroundColor(.whiffSecondaryText2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 리셋 버튼
                    Button(action: {
                        print("🔘 [ImageEditor] 리셋 버튼 클릭")
                        resetTransform()
                    }) {
                        Text("초기화")
                            .foregroundColor(.whiffPrimaryText)
                            .frame(minHeight: 44)
                            .frame(maxWidth: .infinity)
                            .background(Color.whiffSectionBackground)
                            .clipShape(Capsule())
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
                .background(Color.whiffMainBackground)
            }
            .background(Color.whiffMainBackground)
            .navigationBarHidden(true)
        }
        .onAppear {
            print("📱 [ImageEditor] 뷰가 나타남")
        }
        .onDisappear {
            print("📱 [ImageEditor] 뷰가 사라짐")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getAspectRatioIcon(_ ratio: AspectRatio) -> String {
        switch ratio {
        case .original: return "rectangle"
        case .square: return "square"
        case .portrait: return "rectangle.portrait"
        case .landscape: return "rectangle"
        }
    }
    
    private func resetTransform() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.0
            offset = .zero
            rotation = 0.0
        }
    }
    
    private func saveEditedImage() {
        print("✅ [이미지 편집] saveEditedImage 호출됨")
        
        // 편집된 이미지 생성
        let editedImage = generateEditedImage()
        print("✅ [이미지 편집] 편집된 이미지 생성 완료: \(editedImage.size)")
        
        onSave(editedImage)
        print("✅ [이미지 편집] onSave 콜백 호출 완료")
    }
    
    private func generateEditedImage() -> UIImage {
        print("🖼️ [이미지 편집] 크롭 시작")
        
        // 1. 원본 이미지의 orientation을 고려한 정규화된 이미지 생성
        let normalizedImage = normalizeImageOrientation(originalImage)
        let originalSize = normalizedImage.size
        
        print("🖼️ [원본 이미지] 크기: \(originalSize)")
        print("🖼️ [편집 상태] scale: \(scale), offset: \(offset), rotation: \(rotation)")
        
        // 2. 간단한 변환 적용
        let renderer = UIGraphicsImageRenderer(size: originalSize)
        let editedImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // 변환 중심점을 이미지 중앙으로 설정
            cgContext.translateBy(x: originalSize.width / 2, y: originalSize.height / 2)
            
            // 스케일, 회전, 오프셋 적용
            cgContext.scaleBy(x: scale, y: scale)
            cgContext.rotate(by: rotation * .pi / 180)
            cgContext.translateBy(x: offset.width, y: offset.height)
            
            // 이미지를 중앙에서 그리기
            cgContext.translateBy(x: -originalSize.width / 2, y: -originalSize.height / 2)
            
            // 이미지 그리기
            normalizedImage.draw(at: .zero)
        }
        
        print("✅ [크롭 완료] 최종 크기: \(editedImage.size)")
        return editedImage
    }
    
    /// UIImage의 orientation을 고려하여 정규화된 이미지 생성
    private func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        // 이미지가 이미 정상 방향이면 그대로 반환
        if image.imageOrientation == .up {
            return image
        }
        
        // orientation을 고려하여 올바른 방향으로 렌더링
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
}

// MARK: - Simple Crop Overlay (새로운 이름으로 중복 방지)
struct SimpleCropOverlay: View {
    let aspectRatio: CGFloat
    let availableSize: CGSize
    
    var body: some View {
        let overlaySize = calculateOverlaySize()
        
        ZStack {
            // 반투명 배경
            Color.black.opacity(0.3)
            
            // 크롭 영역 (투명)
            Rectangle()
                .frame(width: overlaySize.width, height: overlaySize.height)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .allowsHitTesting(false) // 터치 이벤트 통과
        .overlay(
            // 크롭 영역 테두리
            Rectangle()
                .stroke(Color.white, lineWidth: 1)
                .frame(width: overlaySize.width, height: overlaySize.height)
        )
    }
    
    private func calculateOverlaySize() -> CGSize {
        let padding: CGFloat = 40
        let maxWidth = availableSize.width - padding * 2
        let maxHeight = availableSize.height - padding * 2
        
        if aspectRatio == 1.0 {
            // 정사각형
            let size = min(maxWidth, maxHeight)
            return CGSize(width: size, height: size)
        } else if aspectRatio < 1.0 {
            // 세로형
            let width = min(maxWidth, maxHeight * aspectRatio)
            return CGSize(width: width, height: width / aspectRatio)
        } else {
            // 가로형
            let height = min(maxHeight, maxWidth / aspectRatio)
            return CGSize(width: height * aspectRatio, height: height)
        }
    }
}

                                   // MARK: - Croppable Image View
                                   struct CroppableImageView: View {
                                      let image: UIImage
                                      @Binding var scale: CGFloat
                                      @Binding var offset: CGSize
                                      @Binding var rotation: Double
                                      let aspectRatio: CGFloat?
                                      let availableSize: CGSize
                                      
                                      @State private var lastScale: CGFloat = 1.0
                                      @State private var lastOffset: CGSize = .zero
                                      @State private var lastRotation: Double = 0.0
                                      
                                      var body: some View {
                                          GeometryReader { geometry in
                                              ZStack {
                                                  // 이미지 (회전 기능 포함)
                                                  Image(uiImage: image)
                                                      .resizable()
                                                      .aspectRatio(contentMode: .fit)
                                                      .scaleEffect(scale)
                                                      .rotationEffect(.degrees(rotation))
                                                      .offset(offset)
                                                      .clipped()
                                                  
                                                  // 크롭 오버레이
                                                  CropOverlayView(aspectRatio: aspectRatio, availableSize: geometry.size)
                                              }
                                              .simultaneousGesture(
                                                  // 드래그 제스처
                                                  DragGesture()
                                                      .onChanged { value in
                                                          offset = CGSize(
                                                              width: lastOffset.width + value.translation.width,
                                                              height: lastOffset.height + value.translation.height
                                                          )
                                                      }
                                                      .onEnded { _ in
                                                          lastOffset = offset
                                                      }
                                              )
                                              .simultaneousGesture(
                                                  // 확대/축소 제스처
                                                  MagnificationGesture()
                                                      .onChanged { value in
                                                          scale = max(0.5, min(3.0, lastScale * value))
                                                      }
                                                      .onEnded { _ in
                                                          lastScale = scale
                                                      }
                                              )
                                              .simultaneousGesture(
                                                  // 회전 제스처
                                                  RotationGesture()
                                                      .onChanged { value in
                                                          rotation = lastRotation + value.degrees
                                                      }
                                                      .onEnded { _ in
                                                          lastRotation = rotation
                                                      }
                                              )
                                          }
                                      }
                                   }

                                   // MARK: - Crop Overlay View
                                   struct CropOverlayView: View {
                                      let aspectRatio: CGFloat?
                                      let availableSize: CGSize
                                      
                                      var cropSize: CGSize {
                                          let padding: CGFloat = 40
                                          let maxWidth = availableSize.width - padding * 2
                                          let maxHeight = availableSize.height - padding * 2
                                          
                                          // 선택된 비율에 따라 크롭 영역 크기 결정
                                          if let ratio = aspectRatio {
                                              if ratio == 1.0 {
                                                  // 정사각형
                                                  let size = min(maxWidth, maxHeight)
                                                  return CGSize(width: size, height: size)
                                              } else if ratio < 1.0 {
                                                  // 세로형 (4:5 등)
                                                  let width = min(maxWidth, maxHeight * ratio)
                                                  let height = width / ratio
                                                  return CGSize(width: width, height: height)
                                              } else {
                                                  // 가로형 (16:9 등)
                                                  let height = min(maxHeight, maxWidth / ratio)
                                                  let width = height * ratio
                                                  return CGSize(width: width, height: height)
                                              }
                                          } else {
                                              // 원본 비율 - 가능한 한 크게
                                              let size = min(maxWidth, maxHeight)
                                              return CGSize(width: size, height: size)
                                          }
                                      }
                                      
                                      var body: some View {
                                          ZStack {
                                              // 어두운 오버레이
                                              Color.whiffPrimaryText.opacity(0.5)
                                              
                                              // 크롭 영역 (투명)
                                              Rectangle()
                                                  .frame(width: cropSize.width, height: cropSize.height)
                                                  .blendMode(.destinationOut)
                                          }
                                          .compositingGroup()
                                          .overlay(cropFrameOverlay)
                                      }
                                      
                                      @ViewBuilder
                                      private var cropFrameOverlay: some View {
                                          ZStack {
                                              // 외부 테두리
                                              Rectangle()
                                                  .stroke(Color.whiffWhiteText, lineWidth: 2)
                                                  .frame(width: cropSize.width, height: cropSize.height)
                                              
                                              // 세로 가이드 라인
                                              verticalGridLines
                                              
                                              // 가로 가이드 라인
                                              horizontalGridLines
                                          }
                                      }
                                      
                                      @ViewBuilder
                                      private var verticalGridLines: some View {
                                          VStack(spacing: 0) {
                                              Rectangle()
                                                  .stroke(Color.whiffWhiteText.opacity(0.5), lineWidth: 1)
                                                  .frame(height: cropSize.height / 3)
                                              Rectangle()
                                                  .stroke(Color.whiffWhiteText.opacity(0.5), lineWidth: 1)
                                                  .frame(height: cropSize.height / 3)
                                              Rectangle()
                                                  .stroke(Color.whiffWhiteText.opacity(0.5), lineWidth: 1)
                                                  .frame(height: cropSize.height / 3)
                                          }
                                          .frame(width: cropSize.width, height: cropSize.height)
                                      }
                                      
                                      @ViewBuilder
                                      private var horizontalGridLines: some View {
                                          HStack(spacing: 0) {
                                              Rectangle()
                                                  .stroke(Color.whiffWhiteText.opacity(0.5), lineWidth: 1)
                                                  .frame(width: cropSize.width / 3)
                                              Rectangle()
                                                  .stroke(Color.whiffWhiteText.opacity(0.5), lineWidth: 1)
                                                  .frame(width: cropSize.width / 3)
                                              Rectangle()
                                                  .stroke(Color.whiffWhiteText.opacity(0.5), lineWidth: 1)
                                                  .frame(width: cropSize.width / 3)
                                          }
                                          .frame(width: cropSize.width, height: cropSize.height)
                                      }
                                   }
