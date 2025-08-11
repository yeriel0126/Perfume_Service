//
//  WhiffApp.swift
//  Whiff
//
//  Created by 신희영 on 2025/05/20.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct WhiffApp: App {
    @StateObject private var projectStore = ProjectStore()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var dailyPerfumeManager = DailyPerfumeManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(projectStore)
                .environmentObject(authViewModel)
                .environmentObject(dailyPerfumeManager)
                .onOpenURL { url in
                    if GIDSignIn.sharedInstance.handle(url) {
                        return
                    }
                }
        }
    }
}
