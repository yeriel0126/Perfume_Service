import SwiftUI

struct OnboardingView: View {
    @Binding var isFirstLaunch: Bool
    @State private var currentPage = 0
    
    let onboardingPages = [
        OnboardingPage(
            image: "sparkles",
            title: "Whiff에 오신 것을 환영합니다!",
            description: "당신만의 향기 여정을 시작해보세요"
        ),
        OnboardingPage(
            image: "heart.fill",
            title: "향수 추천",
            description: "AI가 당신의 취향을 분석하여\n완벽한 향수를 추천해드립니다"
        ),
        OnboardingPage(
            image: "book.fill",
            title: "향기 일기",
            description: "매일의 향기 경험을 기록하고\n특별한 순간들을 보관하세요"
        ),
        OnboardingPage(
            image: "person.2.fill",
            title: "커뮤니티",
            description: "다른 향수 애호가들과\n경험을 공유하고 소통하세요"
        )
    ]
    
    var body: some View {
        ZStack {
            // 배경 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.whiffPrimary.opacity(0.1),
                    Color.purple.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 페이지 인디케이터
                HStack {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.whiffPrimary : Color.whiffSecondaryText2.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
                // 페이지 콘텐츠
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPageView(page: onboardingPages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // 하단 버튼
                VStack(spacing: 16) {
                    if currentPage == onboardingPages.count - 1 {
                        // 마지막 페이지: 시작하기 버튼
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isFirstLaunch = false
                            }
                        }) {
                            Text("시작하기")
                                .font(.headline)
                                .foregroundColor(.whiffWhiteText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.whiffPrimary)
                                .cornerRadius(25)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        // 다음 페이지로 이동
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }) {
                            Text("다음")
                                .font(.headline)
                                .foregroundColor(.whiffPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.whiffPrimary.opacity(0.1))
                                .cornerRadius(25)
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    // 건너뛰기 버튼
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isFirstLaunch = false
                        }
                    }) {
                        Text("건너뛰기")
                            .font(.subheadline)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 아이콘
            Image(systemName: page.image)
                .font(.system(size: 80))
                .foregroundColor(.whiffPrimary)
                .padding(.bottom, 20)
            
            // 제목
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // 설명
            Text(page.description)
                .font(.body)
                .foregroundColor(.whiffSecondaryText2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isFirstLaunch: .constant(true))
} 
