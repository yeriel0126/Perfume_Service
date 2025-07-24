import SwiftUI

struct PerfumeDetailView: View {
    let perfume: PerfumeRecommendation
    @State private var showingReviewSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 향수 이미지
                if let imageUrl = perfume.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                            .tint(.whiffPrimary)
                    }
                    .frame(height: 300)
                }
                
                // 향수 정보
                VStack(alignment: .leading, spacing: 12) {
                    Text(perfume.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.whiffLogo)
                    
                    Text(perfume.brand)
                        .font(.title2)
                        .foregroundColor(.whiffPrimary)
                    
                    if let notes = perfume.notes {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.whiffSecondaryText2)
                            .padding(.top, 8)
                    }
                    
                    HStack {
                        Text("유사도 점수")
                            .font(.headline)
                            .foregroundColor(.whiffLogo)
                        Spacer()
                        if let score = perfume.score {
                            Text(String(format: "%.1f", score))
                                .font(.title3)
                                .foregroundColor(.whiffPrimary)
                        } else {
                            Text("N/A")
                                .font(.title3)
                                .foregroundColor(.whiffSecondaryText2)
                        }
                    }
                    .padding(.top, 8)
                    
                    if let similarity = perfume.similarity {
                        HStack {
                            Text("유사도")
                                .font(.headline)
                                .foregroundColor(.whiffLogo)
                            Spacer()
                            Text(similarity)
                                .font(.title3)
                                .foregroundColor(.whiffPrimary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
                .background(Color.whiffSectionBackground)
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
        .background(Color.whiffMainBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingReviewSheet = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.whiffSecondaryText1)
                }
            }
        }
        .sheet(isPresented: $showingReviewSheet) {
            if let perfumeId = perfume.id {
                ReviewSheet(perfumeId: perfumeId)
            }
        }
    }
}

struct ReviewSheet: View {
    let perfumeId: String
    @Environment(\.dismiss) var dismiss
    @State private var rating = 3
    @State private var comment = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("평점").foregroundColor(.whiffSecondaryText1)) {
                    Picker("Rating", selection: $rating) {
                        ForEach(1...5, id: \.self) { number in
                            Text("\(number)점")
                                .foregroundColor(.whiffPrimaryText)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accentColor(.whiffPrimary)
                }
                
                Section(header: Text("리뷰").foregroundColor(.whiffSecondaryText1)) {
                    TextEditor(text: $comment)
                        .frame(height: 100)
                        .background(Color.whiffSectionBackground)
                        .cornerRadius(8)
                        .foregroundColor(.whiffPrimaryText)
                }
            }
            .background(Color.whiffMainBackground)
                        .navigationTitle("리뷰 작성")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("취소") {
                                    dismiss()
                                }
                                .foregroundColor(.whiffSecondaryText1)
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("저장") {
                                    // TODO: 리뷰 저장 로직 구현
                                    dismiss()
                                }
                                .foregroundColor(.whiffPrimary)
                                .fontWeight(.semibold)
                            }
                        }
        }
        .background(Color.whiffMainBackground)
    }
}

#Preview {
    PerfumeDetailView(perfume: PerfumeRecommendation(
        id: "1",
        name: "Sample Perfume",
        brand: "Sample Brand",
        notes: "Top: Bergamot, Lemon\nMiddle: Jasmine, Rose\nBase: Sandalwood, Musk",
        imageUrl: nil,
        score: 0.85,
        emotionTags: ["신나는", "상쾌한", "시트러스"],
        similarity: "0.85"
    ))
} 
