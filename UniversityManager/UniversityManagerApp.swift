// UniversityManagerApp.swift - VERSIÓN CORREGIDA

import SwiftUI

// 1. PRIMERO define ContentView FUERA del struct App
struct ContentView: View {
    @State private var selectedDestination: AppNavigationDestination? = .classes
    @State private var classesResetToken = UUID()
    
    var body: some View {
        CustomTabBar(
            selectedDestination: $selectedDestination,
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
    @StateObject private var reminderStore = ReminderStore()
    @StateObject private var studyStore = StudyStore()
    @StateObject private var professorStore = ProfessorStore()
    @StateObject private var navigationBarStore = NavigationBarStore()
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
                .environmentObject(reminderStore)
                .environmentObject(studyStore)
                .environmentObject(professorStore)
                .environmentObject(navigationBarStore)
                .preferredColorScheme(.light)
                .onAppear {
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
                    openDeepLink(url)
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
    
    private func openDeepLink(_ url: URL) {
        guard url.scheme == "illuminico" else { return }

        if url.host == "quick-task" || url.path == "/quick-task" {
            openQuickTaskForm(from: url)
            return
        }

        if url.host == "task" {
            openTask(from: url)
        }
    }

    private func openQuickTaskForm(from url: URL) {
        showingQuickTaskForm = true
    }

    private func openTask(from url: URL) {
        let taskIdString = url.pathComponents.dropFirst().first

        guard let taskIdString,
              let taskId = UUID(uuidString: taskIdString),
              let task = taskStore.findTask(by: taskId) else {
            return
        }

        showingQuickTaskForm = false
        taskFromNotification = task
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
