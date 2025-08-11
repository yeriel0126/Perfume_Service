import SwiftUI

struct RecommendationsTabView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var isCardPressed = false
    @State private var isButtonPressed = false
    @State private var showContent = false

    var body: some View {
        ZStack {
            // 배경 패턴
            GeometryReader { geometry in
                // 좌상단 원
                Circle()
                    .fill(Color.whiffPrimary.opacity(0.06))
                    .frame(width: 280, height: 280)
                    .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.15)
                    .blur(radius: 1)
                
                // 우하단 원
                Circle()
                    .fill(Color.whiffPrimary.opacity(0.04))
                    .frame(width: 200, height: 200)
                    .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.8)
                    .blur(radius: 1)
                
                // 중앙 작은 원
                Circle()
                    .fill(Color.whiffPrimary.opacity(0.03))
                    .frame(width: 120, height: 120)
                    .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.4)
                    .blur(radius: 0.5)
            }
            
            VStack(spacing: 0) {
                // 상단 여백
                Spacer()
                    .frame(height: 40)
                
                // 헤더 섹션
                VStack(spacing: 16) {
                    Text("향수 추천")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.primary)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.1), value: showContent)

                    Text("새로운 프로젝트를 시작하고\n당신만의 시그니처 향을 찾아보세요")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: showContent)
                }
                .padding(.horizontal, 24)
                
                // 중간 여백 (균형을 위해)
                Spacer()
                    .frame(height: 60)
                
                // AI 추천 카드
                VStack(spacing: 24) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isCardPressed = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isCardPressed = false
                            }
                        }
                    }) {
                        HStack(spacing: 16) {
                            // 아이콘
                            Image(systemName: "brain")
                                .font(.title)
                                .foregroundColor(.whiffPrimary)
                                .frame(width: 50, height: 50)
                                .background(Color.whiffPrimary.opacity(0.15))
                                .clipShape(Circle())
                                .scaleEffect(isCardPressed ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isCardPressed)
                            
                            // 텍스트 정보
                            VStack(alignment: .leading, spacing: 6) {
                                Text("AI 추천")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("감정 클러스터 기반\n고도화 모델")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(2)
                            }
                            
                            Spacer()
                            
                            // 체크 마크
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.whiffPrimary)
                                .scaleEffect(isCardPressed ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isCardPressed)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.whiffPrimary.opacity(isCardPressed ? 0.08 : 0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.whiffPrimary.opacity(0.3), Color.whiffPrimary.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .scaleEffect(isCardPressed ? 0.98 : 1.0)
                        .shadow(
                            color: Color.whiffPrimary.opacity(isCardPressed ? 0.3 : 0.1),
                            radius: isCardPressed ? 12 : 6,
                            x: 0,
                            y: isCardPressed ? 6 : 3
                        )
                        .animation(.easeInOut(duration: 0.15), value: isCardPressed)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                    .offset(y: showContent ? 0 : 50)
                    .opacity(showContent ? 1.0 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.5), value: showContent)
                }
                
                // 중간 여백
                Spacer()
                    .frame(height: 40)
                
                // 시작 버튼
                NavigationLink(destination:
                    ProjectCreateView(selectedModel: .aiRecommendation)
                        .environmentObject(projectStore)
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .scaleEffect(isButtonPressed ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isButtonPressed)
                        
                        Text("AI 추천으로 시작하기")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.whiffPrimary,
                                Color.whiffPrimary.opacity(0.8),
                                Color.whiffPrimary.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .scaleEffect(isButtonPressed ? 0.96 : 1.0)
                    .shadow(
                        color: Color.whiffPrimary.opacity(isButtonPressed ? 0.5 : 0.3),
                        radius: isButtonPressed ? 15 : 8,
                        x: 0,
                        y: isButtonPressed ? 8 : 4
                    )
                    .animation(.easeInOut(duration: 0.15), value: isButtonPressed)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isButtonPressed = true
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isButtonPressed = false
                            }
                        }
                )
                .padding(.horizontal, 20)
                .offset(y: showContent ? 0 : 50)
                .opacity(showContent ? 1.0 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.7), value: showContent)
                
                // 하단 여백 (탭바 고려)
                Spacer()
                    .frame(height: 100)
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation {
                showContent = true
            }
        }
        .task {
            await loadInitialData()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() async {
        await projectStore.checkModelStatus()
        await projectStore.checkSystemHealth()
    }
}
