import Foundation

class ProjectManager {
    static let shared = ProjectManager()
    private let userDefaults = UserDefaults.standard
    private let projectsKey = "savedProjects"
    
    private init() {}
    
    // 프로젝트 저장
    func saveProject(_ project: ProjectModel) {
        var projects = getAllProjects()
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.append(project)
        }
        
        if let encoded = try? JSONEncoder().encode(projects) {
            userDefaults.set(encoded, forKey: projectsKey)
        }
    }
    
    // 모든 프로젝트 불러오기
    func getAllProjects() -> [ProjectModel] {
        guard let data = userDefaults.data(forKey: projectsKey),
              let projects = try? JSONDecoder().decode([ProjectModel].self, from: data) else {
            return []
        }
        return projects
    }
    
    // 특정 프로젝트 불러오기
    func getProject(id: String) -> ProjectModel? {
        return getAllProjects().first { $0.id == id }
    }
    
    // 프로젝트 삭제
    func deleteProject(id: String) {
        var projects = getAllProjects()
        projects.removeAll { $0.id == id }
        
        if let encoded = try? JSONEncoder().encode(projects) {
            userDefaults.set(encoded, forKey: projectsKey)
        }
    }
    
    // 프로젝트 업데이트
    func updateProject(_ project: ProjectModel) {
        saveProject(project)
    }
} 