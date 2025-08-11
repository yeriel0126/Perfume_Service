import SwiftUI

struct HomeView: View {
    @StateObject private var dailyPerfumeManager = DailyPerfumeManager.shared
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // 헤더
                    VStack(spacing: 8) {
                        Text("Whiff")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.whiffLogo)
                        
                        Text("나만의 향수를 찾아보세요")
                            .font(.subheadline)
                            .foregroundColor(.whiffSecondaryText1)
                    }
                    .padding(.top, 20)
                    
                    // 오늘의 향수 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("오늘의 향수")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.whiffLogo)
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    isRefreshing = true
                                    await dailyPerfumeManager.refreshTodaysPerfume()
                                    isRefreshing = false
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.whiffPrimary)
                                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                    .animation(.linear(duration: 1.0), value: isRefreshing)
                            }
                            .disabled(isRefreshing || dailyPerfumeManager.isLoading)
                        }
                        .padding(.horizontal)
                        
                        if dailyPerfumeManager.isLoading || isRefreshing {
                            TodaysPerfumeLoadingCard()
                        } else if let perfume = dailyPerfumeManager.todaysPerfume {
                            TodaysPerfumeCard(perfume: perfume)
                        } else {
                            TodaysPerfumeErrorCard()
                        }
                    }
                    
                    // 향수 추천 버튼
                    NavigationLink(destination: RecommendationsTabView()) {
                        HStack(spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundColor(.whiffWhiteText)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("향수 추천 받기")
                                    .font(.headline)
                                    .foregroundColor(.whiffWhiteText)
                                
                                Text("나에게 맞는 향수를 찾아보세요")
                                    .font(.caption)
                                    .foregroundColor(.whiffWhiteText.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.whiffWhiteText)
                        }
                        .padding()
                        .background(Color.whiffNextCard)
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .background(Color.whiffMainBackground)
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await dailyPerfumeManager.getTodaysPerfume()
                }
            }
        }
    }
}

// MARK: - 오늘의 향수 카드들

struct TodaysPerfumeCard: View {
    let perfume: Perfume
    
    var body: some View {
        VStack(spacing: 16) {
            // 향수 이미지 (크기 줄임)
            AsyncImage(url: URL(string: perfume.imageURL)) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Rectangle()
                    .fill(Color.whiffSectionBackground)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.whiffSecondaryText2)
                    )
            }
            .frame(height: 180) // 250 -> 180으로 줄임
            .clipped()
            .cornerRadius(12) // 16 -> 12로 줄임
            
            // 향수 정보 (간소화)
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(perfume.name)
                        .font(.title3) // title2 -> title3으로 줄임
                        .bold()
                        .multilineTextAlignment(.leading)
                        .lineLimit(2) // 줄 수 제한
                        .foregroundColor(.whiffPrimaryText)
                    
                    HStack {
                        Text(perfume.brand)
                            .font(.subheadline) // headline -> subheadline으로 줄임
                            .foregroundColor(.whiffPrimary)
                        
                        Spacer()
                        
                        if perfume.price > 0 {
                            Text("₩\(Int(perfume.price).formatted())")
                                .font(.caption) // subheadline -> caption으로 줄임
                                .bold()
                                .foregroundColor(.whiffPrimary)
                        }
                    }
                }
                
                // 설명 (더 간결하게)
                if !perfume.description.isEmpty {
                    Text(perfume.description)
                        .font(.caption)
                        .foregroundColor(.whiffSecondaryText2)
                        .lineLimit(1) // 2줄 -> 1줄로 제한
                        .padding(.top, 2)
                }
                
                // 향조 정보 (더 간결하게)
                VStack(alignment: .leading, spacing: 4) {
                    if !perfume.notes.top.isEmpty {
                        NoteRow(title: "Top", notes: Array(perfume.notes.top.prefix(3))) // 3개로 제한
                    }
                    if !perfume.notes.middle.isEmpty {
                        NoteRow(title: "Middle", notes: Array(perfume.notes.middle.prefix(3))) // 3개로 제한
                    }
                    if !perfume.notes.base.isEmpty {
                        NoteRow(title: "Base", notes: Array(perfume.notes.base.prefix(3))) // 3개로 제한
                    }
                }
                .padding(.top, 4) // 8 -> 4로 줄임
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16) // 20 -> 16으로 줄임
        .background(Color.whiffSectionBackground)
        .cornerRadius(16) // 20 -> 16으로 줄임
        .shadow(color: .whiffPrimaryText.opacity(0.1), radius: 3, x: 0, y: 1) // 그림자 크기 줄임
        .padding(.horizontal)
    }
}

struct NoteRow: View {
    let title: String
    let notes: [String]
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title + ":")
                .font(.caption)
                .bold()
                .foregroundColor(.whiffPrimary)
                .frame(width: 50, alignment: .leading)
            
            Text(notes.joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.whiffSecondaryText2)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct TodaysPerfumeLoadingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .frame(height: 200)
            
            VStack(spacing: 8) {
                Text("오늘의 향수를 불러오는 중...")
                    .font(.headline)
                    .foregroundColor(.whiffSecondaryText2)
            }
        }
        .padding()
        .background(Color.whiffSectionBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct TodaysPerfumeErrorCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
                .frame(height: 200)
            
            VStack(spacing: 8) {
                Text("향수를 불러올 수 없습니다")
                    .font(.headline)
                    .foregroundColor(.whiffSecondaryText2)
                
                Text("나중에 다시 시도해주세요")
                    .font(.caption)
                    .foregroundColor(.whiffSecondaryText2)
            }
        }
        .padding()
        .background(Color.whiffSectionBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
