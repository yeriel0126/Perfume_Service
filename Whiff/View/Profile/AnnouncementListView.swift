import SwiftUI

struct AnnouncementListView: View {
    @StateObject private var announcementManager = AnnouncementManager.shared
    @State private var showingAddAnnouncement = false
    
    var body: some View {
        NavigationView {
            List {
                if announcementManager.announcements.isEmpty {
                    EmptyAnnouncementView()
                } else {
                    ForEach(announcementManager.announcements) { announcement in
                        NavigationLink(destination: AnnouncementDetailView(announcement: announcement)) {
                            AnnouncementRowView(announcement: announcement)
                        }
                    }
                    .onDelete(perform: deleteAnnouncements)
                }
            }
            .background(Color.whiffMainBackground)
            .navigationTitle("공지사항")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddAnnouncement = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.whiffSecondaryText1)
                    }
                }
            }
            .sheet(isPresented: $showingAddAnnouncement) {
                AddAnnouncementView()
            }
            .refreshable {
                announcementManager.loadFromUserDefaults()
            }
        }
    }
    
    private func deleteAnnouncements(offsets: IndexSet) {
        for index in offsets {
            announcementManager.removeAnnouncement(announcementManager.announcements[index])
        }
    }
}

struct AnnouncementRowView: View {
    let announcement: Announcement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(announcement.title)
                            .font(.headline)
                            .foregroundColor(.whiffPrimaryText)
                        
                        if announcement.isImportant {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                    
                    Text("v\(announcement.version)")
                        .font(.caption)
                        .foregroundColor(.whiffWhiteText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.whiffPrimary)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(announcement.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.whiffSecondaryText2)
                    
                    if announcement.isImportant {
                        Text("중요")
                            .font(.caption2)
                            .foregroundColor(.whiffWhiteText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(6)
                    }
                }
            }
            
            Text(announcement.content)
                .font(.body)
                .foregroundColor(.whiffSecondaryText2)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 4)
        .background(Color.whiffMainBackground)
    }
}

struct EmptyAnnouncementView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "megaphone")
                .font(.system(size: 60))
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
        .padding(.vertical, 60)
        .background(Color.whiffMainBackground)
    }
}

struct AnnouncementDetailView: View {
    let announcement: Announcement
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(announcement.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.whiffLogo)
                        
                        if announcement.isImportant {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("v\(announcement.version)")
                            .font(.subheadline)
                            .foregroundColor(.whiffWhiteText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.whiffPrimary)
                            .cornerRadius(12)
                        
                        Text(announcement.date.formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.whiffSecondaryText2)
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                // 내용
                Text(announcement.content)
                    .font(.body)
                    .lineSpacing(6)
                    .foregroundColor(.whiffPrimaryText)
            }
            .padding()
            .background(Color.whiffMainBackground)
        }
        .background(Color.whiffMainBackground)
        .navigationTitle("공지사항")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddAnnouncementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var announcementManager = AnnouncementManager.shared
    
    @State private var title = ""
    @State private var content = ""
    @State private var version = Bundle.appVersion  // 기본값을 현재 버전으로
    @State private var isImportant = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("공지사항 정보")
                                    .foregroundColor(.whiffSecondaryText1)
                                ) {
                                    TextField("제목", text: $title)
                                        .foregroundColor(.whiffPrimaryText)
                                    TextField("버전 (예: 1.0.0)", text: $version)
                                        .foregroundColor(.whiffPrimaryText)
                                    Toggle("중요 공지사항", isOn: $isImportant)
                                        .tint(.whiffPrimary)
                }
                
                Section(header: Text("내용")
                                    .foregroundColor(.whiffSecondaryText1)
                                ) {
                                    TextEditor(text: $content)
                                        .frame(minHeight: 200)
                                        .background(Color.whiffSectionBackground)
                                        .foregroundColor(.whiffPrimaryText)
                }
            }
            .background(Color.whiffMainBackground)
            .navigationTitle("공지사항 추가")
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
                        saveAnnouncement()
                    }
                    .foregroundColor(.whiffPrimary)
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || content.isEmpty || version.isEmpty)
                }
            }
        }
        .background(Color.whiffMainBackground)
    }
    
    private func saveAnnouncement() {
        let announcement = Announcement(
            title: title,
            content: content,
            version: version,
            isImportant: isImportant
        )
        
        announcementManager.addAnnouncement(announcement)
        dismiss()
    }
}

#Preview {
    AnnouncementListView()
} 
