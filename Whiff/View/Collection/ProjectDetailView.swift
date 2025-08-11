//
//  ProjectDetailView.swift
//  Whiff
//
//  Created by 신희영 on 5/20/25.
//
import SwiftUI
import Foundation

struct ProjectDetailView: View {
    let project: Project
    @State private var showingAddNote = false
    @State private var selectedPerfume: Perfume?
    @EnvironmentObject var projectStore: ProjectStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 프로젝트 정보
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(project.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.whiffLogo)
                        
                        Spacer()
                        
                        Button(action: {
                            // TODO: 즐겨찾기 기능 추가
                        }) {
                            Image(systemName: "star")
                                .foregroundColor(.whiffSecondaryText2)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Text("생성일: \(project.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.subheadline)
                            .foregroundColor(.whiffSecondaryText2)
                        
                        Text("\(project.recommendations.count)개 향수")
                            .font(.subheadline)
                            .foregroundColor(.whiffPrimary)
                    }
                    
                    // 태그들
                    if !project.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(project.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.whiffSectionBackground)
                                        .foregroundColor(.whiffSecondaryText1)
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }
                .padding(.horizontal)
                
                // 향수 추천 목록
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("추천 향수")
                            .font(.headline)
                            .foregroundColor(.whiffLogo)
                        
                        Spacer()
                        
                        Text("총 \(project.recommendations.count)개")
                            .font(.caption)
                            .foregroundColor(.whiffSecondaryText2)
                    }
                    .padding(.horizontal)
                    
                    LazyVStack(spacing: 16) {
                        ForEach(project.recommendations, id: \.id) { perfume in
                            PerfumeDetailCard(perfume: perfume)
                                .onTapGesture {
                                    selectedPerfume = perfume
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 삭제 버튼
                Button(action: {
                    projectStore.removeProject(project)
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("이 프로젝트 삭제")
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.whiffSectionBackground)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding(.vertical)
        }
        .background(Color.whiffMainBackground)
        .navigationTitle("추천 상세")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPerfume) { perfume in
            PerfumeSheetView(perfume: perfume)
        }
    }
}

// MARK: - 향수 상세 카드
struct PerfumeDetailCard: View {
    let perfume: Perfume
    
    var body: some View {
        HStack(spacing: 16) {
            // 향수 이미지
            AsyncImage(url: URL(string: perfume.imageURL)) { image in
                image
                    .resizable()
                    .scaledToFit()  // .scaledToFill → .scaledToFit 변경
                    .frame(width: 80, height: 100)
                    .background(Color.whiffSectionBackground)  // 배경 추가
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.whiffSectionBackground)
                    .frame(width: 80, height: 100)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.whiffSecondaryText2)
                    )
            }
            .cornerRadius(12)  // clipShape 대신 cornerRadius 사용
            
            // 향수 정보
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(perfume.name)
                        .font(.headline)
                        .bold()
                        .foregroundColor(.whiffPrimaryText)
                    
                    Text(perfume.brand)
                        .font(.subheadline)
                        .foregroundColor(.whiffPrimary)
                }
                
                // 매치 점수
                if perfume.similarity > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.caption)
                        
                        Text("매치도 \(String(format: "%.1f", perfume.similarity * 100))%")
                            .font(.caption)
                            .foregroundColor(.pink)
                    }
                }
                
                // 감정 태그
                if !perfume.emotionTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(perfume.emotionTags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.whiffSectionBackground)
                                    .foregroundColor(.whiffSecondaryText1)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            Spacer()
            
            // 상세보기 버튼
            Image(systemName: "chevron.right")
                .foregroundColor(.whiffSecondaryText2)
        }
        .padding()
        .background(Color.whiffSectionBackground)
        .cornerRadius(16)
    }
}

// MARK: - 향수 시트 뷰
struct PerfumeSheetView: View {
    let perfume: Perfume
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 향수 이미지와 기본 정보
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: perfume.imageURL)) { image in
                            image
                                .resizable()
                                .scaledToFit()  // .scaledToFill → .scaledToFit 변경
                                .frame(maxHeight: 250)  // 최대 높이 설정
                                .frame(maxWidth: .infinity)
                                .background(Color.whiffSectionBackground)  // 배경 추가
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.whiffSectionBackground)
                                .frame(height: 200)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.whiffSecondaryText2)
                                )
                        }
                        .cornerRadius(16)  // clipShape 대신 cornerRadius 사용
                        
                        VStack(spacing: 8) {
                            Text(perfume.name)
                                .font(.title2)
                                .bold()
                                .multilineTextAlignment(.center)
                                .foregroundColor(.whiffPrimaryText)
                            
                            Text(perfume.brand)
                                .font(.headline)
                                .foregroundColor(.whiffPrimary)
                        }
                    }
                    
                    // 매치 점수
                    if perfume.similarity > 0 {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                            
                            Text("매치도")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.whiffPrimaryText)
                            
                            Spacer()
                            
                            Text("\(String(format: "%.1f", perfume.similarity * 100))%")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.pink)
                        }
                        .padding()
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // 감정 태그
                    if !perfume.emotionTags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("감정 특성")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.whiffLogo)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(perfume.emotionTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.whiffSectionBackground)
                                        .foregroundColor(.whiffSecondaryText1)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .background(Color.whiffSectionBackground)
                        .cornerRadius(12)
                    }
                    
                    // 향수 설명
                    if !perfume.description.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI 추천 분석")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.whiffLogo)
                            Text(perfume.description)
                                .font(.body)
                                .foregroundColor(.whiffSecondaryText2)
                        }
                        .padding()
                        .background(Color.whiffSectionBackground)
                        .cornerRadius(12)
                    }
                    
                    // 향 노트 (있을 경우)
                    if !perfume.notes.top.isEmpty || !perfume.notes.middle.isEmpty || !perfume.notes.base.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("향 노트")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.whiffLogo)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                if !perfume.notes.top.isEmpty {
                                    HStack {
                                        Text("Top:")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.whiffPrimary)
                                        Text(perfume.notes.top.joined(separator: ", "))
                                            .font(.subheadline)
                                            .foregroundColor(.whiffPrimaryText)
                                    }
                                }
                                
                                if !perfume.notes.middle.isEmpty {
                                    HStack {
                                        Text("Middle:")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.whiffPrimary)
                                        Text(perfume.notes.middle.joined(separator: ", "))
                                            .font(.subheadline)
                                            .foregroundColor(.whiffPrimaryText)
                                    }
                                }
                                
                                if !perfume.notes.base.isEmpty {
                                    HStack {
                                        Text("Base:")
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.whiffPrimary)
                                        Text(perfume.notes.base.joined(separator: ", "))
                                            .font(.subheadline)
                                            .foregroundColor(.whiffPrimaryText)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.whiffSectionBackground)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.whiffMainBackground)
            }
            .background(Color.whiffMainBackground)
            .navigationTitle("향수 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundColor(.whiffSecondaryText1) 
                }
            }
        }
    }
}

struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let samplePerfumes = [
            Perfume(
                id: "1",
                name: "Sample Perfume 1",
                brand: "Sample Brand",
                imageURL: "https://picsum.photos/200/300?random=1",
                price: 120000,
                description: "신선하고 상쾌한 시트러스 향수입니다. 레몬과 베르가모트의 톱 노트가 자스민과 로즈의 미들 노트와 조화를 이루며, 샌달우드와 머스크의 베이스 노트로 마무리됩니다.",
                notes: PerfumeNotes(
                    top: ["Bergamot", "Lemon"],
                    middle: ["Jasmine", "Rose"],
                    base: ["Sandalwood", "Musk"]
                ),
                rating: 4.5,
                emotionTags: ["신나는", "상쾌한", "시트러스"],
                similarity: 0.85
            ),
            Perfume(
                id: "2",
                name: "Sample Perfume 2",
                brand: "Another Brand",
                imageURL: "https://picsum.photos/200/300?random=2",
                price: 95000,
                description: "차분하고 로맨틱한 플로럴 우드 향수입니다. 오렌지와 자몽의 생동감 있는 시작과 라벤더와 로즈의 우아한 중간 향, 바닐라와 앰버의 따뜻한 마무리가 특징입니다.",
                notes: PerfumeNotes(
                    top: ["Orange", "Grapefruit"],
                    middle: ["Lavender", "Rose"],
                    base: ["Vanilla", "Amber"]
                ),
                rating: 4.2,
                emotionTags: ["차분한", "로맨틱한", "우드"],
                similarity: 0.75
            )
        ]
        
        return ProjectDetailView(project: Project(
            id: UUID(),
            name: "Sample Project",
            recommendations: samplePerfumes,
            emotionSummary: "테스트용 감정 분석 요약입니다.",
            createdDate: Date(),
            userPreferences: PerfumePreferences(
                gender: "Female",
                seasonTags: "Spring",
                timeTags: "Day",
                desiredImpression: "Fresh, Confident",
                activity: "Casual",
                weather: "Sunny"
            ),
            userNoteRatings: ["citrus": 5, "floral": 4, "woody": 3]
        ))
        .environmentObject(ProjectStore())
    }
}

