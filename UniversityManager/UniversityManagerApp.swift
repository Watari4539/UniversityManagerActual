// UniversityManagerApp.swift - VERSIÓN CORREGIDA

import SwiftUI

// 1. PRIMERO define ContentView FUERA del struct App
struct ContentView: View {
    @State private var selectedTab = 2
    @State private var classesResetToken = UUID()
    
    var body: some View {
        CustomTabBar(
            selectedTab: $selectedTab,
            classesResetToken: $classesResetToken
        )
            .accentColor(.blue)
    }
}

// 2. LUEGO define UniversityManagerApp
@main
struct UniversityManagerApp: App {
    @StateObject private var classStore = ClassStore()
    @StateObject private var taskStore = TaskStore()
    @StateObject private var examStore = ExamStore()
    @StateObject private var gradeStore = GradeStore()
    @StateObject private var notifications = NotificationManager.shared
    
    init() {
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(classStore)
                .environmentObject(taskStore)
                .environmentObject(examStore)
                .environmentObject(gradeStore)
                .preferredColorScheme(.light)
                .onAppear {
                                    // ESTO FORZA EL PERMISO AL ABRIR LA APP
                    NotificationManager.shared.requestAuthorization()
                }
        }
    }
    
    private func configureAppearance() {
        // Configuración de UI...
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}
