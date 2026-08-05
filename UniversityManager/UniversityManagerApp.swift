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
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var classStore = ClassStore()
    @StateObject private var taskStore = TaskStore()
    @StateObject private var examStore = ExamStore()
    @StateObject private var gradeStore = GradeStore()
    @StateObject private var notifications = NotificationManager.shared
    @State private var showingQuickTaskForm = false
    @State private var taskFromNotification: TaskItem?
    
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
                    openQuickTaskFormIfNeeded()
                    openPendingNotificationTaskIfNeeded()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        openQuickTaskFormIfNeeded()
                        openPendingNotificationTaskIfNeeded()
                    }
                }
                .onOpenURL { url in
                    openQuickTaskForm(from: url)
                }
                .onReceive(NotificationCenter.default.publisher(for: NotificationManager.taskNotificationTapped)) { _ in
                    openPendingNotificationTaskIfNeeded()
                }
                .sheet(isPresented: $showingQuickTaskForm) {
                    TaskFormView(
                        classId: classStore.classes(for: classStore.currentSemester)
                            .sorted { $0.name < $1.name }
                            .first?.id,
                        allowsClassSelection: true
                    )
                    .environmentObject(classStore)
                    .environmentObject(taskStore)
                }
                .sheet(item: $taskFromNotification) { task in
                    TaskDetailView(task: task)
                        .environmentObject(classStore)
                        .environmentObject(taskStore)
                }
        }
    }
    
    private func openQuickTaskForm(from url: URL) {
        guard url.scheme == "illuminico" else { return }
        guard url.host == "quick-task" || url.path == "/quick-task" else { return }
        showingQuickTaskForm = true
    }
    
    private func openQuickTaskFormIfNeeded() {
        if SharedAppStorage.consumeQuickTaskRequest() {
            showingQuickTaskForm = true
        }
    }

    private func openPendingNotificationTaskIfNeeded() {
        guard let taskId = notifications.consumePendingTaskNotificationId(),
              let task = taskStore.findTask(by: taskId) else {
            return
        }

        showingQuickTaskForm = false
        taskFromNotification = task
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
