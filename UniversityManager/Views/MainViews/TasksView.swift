import SwiftUI
import UIKit  // ← AÑADIDO para haptic feedback

struct TasksView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var classStore: ClassStore
    @State private var showingTaskDetail: TaskItem?
    @State private var showingEditTask: TaskItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tareas Próximas")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("\(taskStore.upcomingTasks().count) tareas pendientes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Tasks List
                        if taskStore.upcomingTasks().isEmpty {
                            EmptyStateView(
                                icon: "checkmark.circle",
                                title: "Sin tareas pendientes",
                                message: "¡Sos un crack pa! No tienes tareas próximas."
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(taskStore.upcomingTasks()) { task in
                                    TaskCard(task: task, classStore: classStore) 
                                    .onTapGesture {
                                        showingTaskDetail = task
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        // Acción de completar con swipe
                                        Button {
                                            hapticSuccess()
                                            withAnimation(.spring()) {
                                                taskStore.markAsCompleted(task)
                                            }
                                        } label: {
                                            Label("Completar", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(.green)
                                        
                                        // Acción de eliminar
                                        Button(role: .destructive) {
                                            withAnimation {
                                                taskStore.deleteTask(task)
                                            }
                                        } label: {
                                            Label("Eliminar", systemImage: "trash.fill")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        // Acción para ver detalles
                                        Button {
                                            showingTaskDetail = task
                                        } label: {
                                            Label("Detalles", systemImage: "info.circle")
                                        }
                                        .tint(.blue)
                                        
                                        // Acción para editar
                                        Button {
                                            showingEditTask = task
                                        } label: {
                                            Label("Editar", systemImage: "pencil")
                                        }
                                        .tint(.orange)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $showingTaskDetail) { task in
                TaskDetailView(task: task)
            }
            .sheet(item: $showingEditTask) { task in
                TaskFormView(classId: task.classId, editingTask: task)
            }
        }
    }
    
    // Función para haptic feedback
    private func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 80)
    }
}
