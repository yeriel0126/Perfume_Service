import SwiftUI
import Foundation

struct ScentDiaryView: View {
    @StateObject private var viewModel = ScentDiaryViewModel()
    @State private var showingNewDiarySheet = false
    @State private var showingDiaryDetail = false
    @State private var selectedDiary: ScentDiaryModel?
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.whiffMainBackground,
                        Color.whiffGradientEnd.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 통계 정보
                        HStack(spacing: 20) {
                            StatCard(title: "총 일기", value: "\(viewModel.sortedDiaries.count)")
                            StatCard(title: "이번 달", value: "\(viewModel.sortedDiaries.filter { Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .month) }.count)")
                            StatCard(title: "공개", value: "\(viewModel.sortedDiaries.count)")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // 디버깅 버튼 (개발 중에만 표시)
                        #if DEBUG
                        HStack(spacing: 12) {
                            Button("데이터 확인") {
                                viewModel.debugLocalData()
                            }
                            .font(.caption)
                            .foregroundColor(.whiffPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.whiffPrimary.opacity(0.1))
                            .clipShape(Capsule())
                            
                            Button("새로고침") {
                                Task {
                                    await viewModel.fetchDiaries()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.whiffSecondaryText1.opacity(0.1))
                            .clipShape(Capsule())
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        #endif
                        
                        if viewModel.sortedDiaries.isEmpty && !viewModel.isLoading {
                            // 비어있는 상태
                            EmptyDiaryStateView {
                                showingNewDiarySheet = true
                            }
                        } else {
                            // 일기 피드
                            LazyVStack(spacing: 0) { // 인스타그램처럼 카드 사이 간격 없애기
                                ForEach(viewModel.sortedDiaries) { diary in
                                    InstagramStyleDiaryCard(diary: diary, viewModel: viewModel)
                                        .onTapGesture {
                                            selectedDiary = diary
                                            showingDiaryDetail = true
                                        }
                                    
                                    // 카드 사이 구분선
                                    if diary.id != viewModel.sortedDiaries.last?.id {
                                        Divider()
                                            .padding(.vertical, 8)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 일기 작성 버튼 (인스타그램 스타일 플로팅 버튼)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingNewDiarySheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.whiffWhiteText)
                                .frame(width: 56, height: 56)
                                .background(
                                    LinearGradient(
                                                    gradient: Gradient(colors: [Color.whiffGradientStart, Color.whiffGradientEnd]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .whiffPrimaryText.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 30)
                    }
                }
                
                // 로딩 상태
                if viewModel.isLoading {
                    ProgressView("시향 일기를 불러오는 중...")
                        .foregroundColor(.whiffPrimaryText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.whiffMainBackground.opacity(0.8))
                }
            }
            .navigationTitle("시향 일기")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.fetchDiaries()
            }
            .sheet(isPresented: $showingNewDiarySheet) {
                NewScentDiaryView(selectedTab: $selectedTab)
            }
            .sheet(isPresented: $showingDiaryDetail) {
                if let diary = selectedDiary {
                    ScentDiaryDetailView(diary: diary, viewModel: viewModel)
                }
            }
            .alert("오류", isPresented: $viewModel.showError) {
                Button("확인") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "알 수 없는 오류가 발생했습니다.")
            }
            .onAppear {
                Task {
                    if viewModel.diaries.isEmpty {
                        await viewModel.fetchDiaries()
                    }
                    
                    // 디버깅: 메인화면에 표시되는 일기 개수 확인
                    print("📱 [ScentDiaryView] 화면 표시 상태:")
                    print("   - 전체 일기: \(viewModel.diaries.count)개")
                    print("   - 공개 일기: \(viewModel.sortedDiaries.count)개")
                    print("   - 비공개 일기: \(viewModel.allSortedDiaries.count - viewModel.sortedDiaries.count)개")
                    print("   - 로딩 중: \(viewModel.isLoading)")
                    
                    if viewModel.sortedDiaries.isEmpty {
                        print("⚠️ [ScentDiaryView] 표시할 공개 일기가 없습니다!")
                    }
                }
            }
            .onChange(of: showingNewDiarySheet) { _, isShowing in
                // 새 일기 작성 화면이 닫힐 때 목록 새로고침 (NewScentDiaryView에서 이미 처리하므로 제거)
                // if !isShowing {
                //     Task {
                //         await viewModel.fetchDiaries()
                //         print("✅ [ScentDiaryView] 일기 작성 후 목록 새로고침 완료")
                //     }
                // }
            }
        }
    }
}

// MARK: - 비어있는 상태 뷰
struct EmptyDiaryStateView: View {
    let onCreateDiary: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 일러스트레이션
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.whiffGradientStart, Color.whiffGradientEnd]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "book.pages")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.whiffGradientStart, Color.whiffGradientEnd]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("첫 번째 시향 일기를 작성해보세요")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.whiffPrimaryText)
                    .multilineTextAlignment(.center)
                
                Text("오늘 뿌린 향수와 함께한\n특별한 순간을 기록해보세요")
                    .font(.body)
                    .foregroundColor(.whiffSecondaryText2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button(action: onCreateDiary) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("첫 번째 일기 작성하기")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.whiffWhiteText)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.whiffGradientStart, Color.whiffGradientEnd]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .whiffPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 인스타그램 스타일 카드
struct InstagramStyleDiaryCard: View {
    let diary: ScentDiaryModel
    @ObservedObject var viewModel: ScentDiaryViewModel
    @State private var showingActionSheet = false
    @State private var showingReportSheet = false
    @State private var reportReason = ""
    @State private var showReportSuccess = false
    @State private var showReportError = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 사용자 정보 헤더
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: diary.userProfileImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.whiffSecondaryText2)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(diary.userName.isEmpty || diary.userName == "익명 사용자" ? "사용자" : diary.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.whiffPrimaryText)
                    
                    Text(viewModel.formatDate(diary.createdAt))
                        .font(.caption)
                        .foregroundColor(.whiffSecondaryText2)
                }
                
                Spacer()
                
                // 공개/비공개 표시
                HStack(spacing: 4) {
                    if !diary.isPublic {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                    
                    // 더보기 메뉴
                    Button(action: {
                        showingActionSheet = true
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.caption)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // 이미지 섹션 (있을 경우)
            if let imageUrl = diary.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill) // 정사각형 비율로 수정
                            .frame(maxWidth: .infinity)
                            .clipped()
                    case .failure(let error):
                        // 로컬 파일 경로인 경우 UIImage로 로드 시도
                        if imageUrl.hasPrefix("file://") {
                            LocalImageView(imageUrl: imageUrl)
                        } else {
                            Rectangle()
                                .fill(Color.whiffSectionBackground)
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.whiffSecondaryText2)
                                        Text("이미지를 불러올 수 없습니다")
                                            .font(.caption)
                                            .foregroundColor(.whiffSecondaryText2)
                                        Text("오류: \(error.localizedDescription)")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                    }
                                )
                        }
                    case .empty:
                        Rectangle()
                            .fill(Color.whiffSectionBackground)
                            .frame(height: 200)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            // 액션 버튼들
            HStack(spacing: 16) {
                // 좋아요 버튼
                Button(action: {
                    Task {
                        await viewModel.toggleLike(diary.id)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isLiked(diary.id) ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.isLiked(diary.id) ? .red : .whiffPrimaryText)
                        Text("\(diary.likes)")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                }
                .buttonStyle(.plain)
                
                // 댓글 버튼 (임시)
                Button(action: {
                    // TODO: 댓글 액션
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.whiffPrimaryText)
                        Text("\(diary.comments)")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // 향수 정보 버튼
                if diary.perfumeName != "향수 없음" {
                    Button(action: {
                        // TODO: 향수 정보 액션
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.whiffPrimary)
                            Text(diary.perfumeName)
                                .font(.caption)
                                .foregroundColor(.whiffPrimary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.whiffPrimary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // 본문 내용과 태그 (항상 표시)
            VStack(alignment: .leading, spacing: 8) {
                // 사용자명과 본문
                HStack(alignment: .top, spacing: 8) {
                    Text(diary.userName.isEmpty || diary.userName == "익명 사용자" ? "사용자" : diary.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.whiffPrimaryText)
                    
                    if !diary.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(diary.content)
                            .font(.subheadline)
                            .foregroundColor(.whiffPrimaryText)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil) // 전체 내용 표시
                            .onAppear {
                                print("📝 [내용 표시] 일기 ID: \(diary.id), 내용: '\(diary.content)'")
                            }
                    } else {
                        Text("시향 일기를 작성했습니다.")
                            .font(.subheadline)
                            .foregroundColor(.whiffSecondaryText2)
                            .onAppear {
                                print("⚠️ [빈 내용] 일기 ID: \(diary.id), 내용이 비어있음")
                            }
                    }
                    
                    Spacer(minLength: 0)
                }
                
                // 감정 태그들 (항상 표시)
                if !diary.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(diary.tags.prefix(5), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(.whiffPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.whiffPrimary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            
                            if diary.tags.count > 5 {
                                Text("+\(diary.tags.count - 5)")
                                    .font(.caption)
                                    .foregroundColor(.whiffSecondaryText2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.whiffSecondaryText2.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .onAppear {
                        print("🏷️ [태그 표시] 일기 ID: \(diary.id), 태그: \(diary.tags)")
                    }
                } else {
                    // 태그가 없을 때 플레이스홀더
                    HStack {
                        Text("태그가 없습니다")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .onAppear {
                        print("⚠️ [빈 태그] 일기 ID: \(diary.id), 태그가 비어있음")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
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
        .onAppear {
            // 디버깅 로그 추가
            print("🐛 [InstagramCard] 일기 표시:")
            print("   - ID: \(diary.id)")
            print("   - 사용자: '\(diary.userName)'")
            print("   - 내용 길이: \(diary.content.count)자")
            print("   - 내용: '\(diary.content)'")
            print("   - 태그 개수: \(diary.tags.count)개")
            print("   - 태그: \(diary.tags)")
            print("   - 이미지: \(diary.imageUrl ?? "없음")")
            print("   - 공개: \(diary.isPublic)")
            print("   - 내용 isEmpty: \(diary.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)")
            print("   - 태그 isEmpty: \(diary.tags.isEmpty)")
        }
    }
    
    private func reportDiary() {
        guard let url = URL(string: "https://whiff-api-9nd8.onrender.com/reports/diary") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "target_id": diary.id,
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

// MARK: - 로컬 이미지 뷰 (file:// URL 처리용)
struct LocalImageView: View {
    let imageUrl: String
    @State private var image: UIImage?
    
    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.whiffSectionBackground)
                .frame(height: 200)
                .overlay(
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("로컬 이미지 로딩 중...")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                )
                .onAppear {
                    loadLocalImage()
                }
        }
    }
    
    private func loadLocalImage() {
        guard let url = URL(string: imageUrl) else { return }
        
        DispatchQueue.global(qos: .userInteractive).async {
            if let data = try? Data(contentsOf: url),
               let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                    print("✅ [LocalImageView] 로컬 이미지 로드 성공: \(imageUrl)")
                }
            } else {
                print("❌ [LocalImageView] 로컬 이미지 로드 실패: \(imageUrl)")
            }
        }
    }
}

// MARK: - 일기 상세 보기
struct ScentDiaryDetailView: View {
    let diary: ScentDiaryModel
    @ObservedObject var viewModel: ScentDiaryViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 헤더
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("시향 일기")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.whiffPrimaryText)
                                
                                Text("오늘의 향수와 함께한 특별한 순간들")
                                    .font(.subheadline)
                                    .foregroundColor(.whiffSecondaryText2)
                            }
                            
                            Spacer()
                            
                            // 디버깅 버튼 (개발 중에만 표시)
                            #if DEBUG
                            VStack(spacing: 8) {
                                Button("데이터 확인") {
                                    viewModel.debugLocalData()
                                }
                                .font(.caption)
                                .foregroundColor(.whiffPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.whiffPrimary.opacity(0.1))
                                .clipShape(Capsule())
                                
                                Button("데이터 초기화") {
                                    viewModel.clearLocalDiaries()
                                    Task {
                                        await viewModel.fetchDiaries()
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            #endif
                        }
                        .padding(.horizontal, 24)
                        
                        // 통계 정보
                        HStack(spacing: 20) {
                            StatCard(title: "총 일기", value: "\(viewModel.sortedDiaries.count)")
                            StatCard(title: "이번 달", value: "\(viewModel.sortedDiaries.filter { Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .month) }.count)")
                            StatCard(title: "공개", value: "\(viewModel.sortedDiaries.count)")
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    
                    // 이미지 (있을 경우)
                    if let imageUrl = diary.imageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure(_):
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.whiffSectionBackground)
                                    .frame(height: 200)
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
                            case .empty:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.whiffSectionBackground)
                                    .frame(height: 200)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 본문 내용
                    VStack(alignment: .leading, spacing: 16) {
                        Text("시향 일기")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.whiffPrimaryText)
                        
                        Text(diary.content)
                            .font(.body)
                            .foregroundColor(.whiffPrimaryText)
                            .lineSpacing(6)
                            .multilineTextAlignment(.leading)
                        
                        // 감정 태그들
                        if !diary.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("감정 태그")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.whiffPrimaryText)
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 80))
                                ], spacing: 8) {
                                    ForEach(diary.tags, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.subheadline)
                                            .foregroundColor(.whiffPrimary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.whiffPrimary.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.whiffMainBackground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("시향 일기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

// MARK: - 통계 카드 컴포넌트
struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.whiffPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.whiffSecondaryText2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.whiffMainBackground)
                .shadow(color: .whiffPrimaryText.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct ScentDiaryView_Previews: PreviewProvider {
    static var previews: some View {
        ScentDiaryView(selectedTab: .constant(1))
    }
}
