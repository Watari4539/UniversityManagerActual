import SwiftUI
import UIKit  // ← AÑADIDO para haptic feedback

struct TasksView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var classStore: ClassStore
    @State private var expandedTask: TaskItem?
    @State private var showingEditTask: TaskItem?
    @State private var taskPendingDeletion: TaskItem?
    @Namespace private var taskExpansionNamespace
    private let tabBarClearance: CGFloat = 96
    
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
                                        .matchedGeometryEffect(
                                            id: task.id,
                                            in: taskExpansionNamespace,
                                            properties: .frame,
                                            isSource: expandedTask?.id != task.id
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
                                                expandedTask = task
                                            }
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
                                                taskPendingDeletion = task
                                            } label: {
                                                Label("Eliminar", systemImage: "trash.fill")
                                            }
                                        }
                                        .swipeActions(edge: .leading) {
                                            // Acción para ver detalles
                                            Button {
                                                withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
                                                    expandedTask = task
                                                }
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
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: tabBarClearance)
                }

                if let expandedTask {
                    expandedTaskOverlay(for: expandedTask)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $showingEditTask) { task in
                TaskFormView(classId: task.classId, editingTask: task)
            }
            .alert(item: $taskPendingDeletion) { task in
                Alert(
                    title: Text("¿Eliminar esta tarea?"),
                    message: Text("Esta acción no se puede deshacer. La tarea se eliminará permanentemente."),
                    primaryButton: .destructive(Text("Eliminar")) {
                        taskStore.deleteTask(task)
                        closeExpandedTask()
                        taskPendingDeletion = nil
                    },
                    secondaryButton: .cancel {
                        taskPendingDeletion = nil
                    }
                )
            }
        }
    }
    
    // Función para haptic feedback
    private func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func expandedTaskOverlay(for task: TaskItem) -> some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    closeExpandedTask()
                }

            UpcomingTaskExpandedCard(
                task: task,
                namespace: taskExpansionNamespace,
                onClose: closeExpandedTask,
                onEdit: {
                    closeExpandedTask()
                    showingEditTask = task
                },
                onComplete: {
                    hapticSuccess()
                    taskStore.markAsCompleted(task)
                    closeExpandedTask()
                },
                onDelete: {
                    taskPendingDeletion = task
                }
            )
            .environmentObject(classStore)
            .padding(.horizontal, 18)
            .padding(.bottom, tabBarClearance)
            .frame(maxWidth: 520)
            .transition(.opacity)
        }
        .zIndex(20)
    }

    private func closeExpandedTask() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
            expandedTask = nil
        }
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

private struct UpcomingTaskExpandedCard: View {
    @EnvironmentObject var classStore: ClassStore
    let task: TaskItem
    let namespace: Namespace.ID
    let onClose: () -> Void
    let onEdit: () -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void

    private var classItem: UniversityClass? {
        classStore.findClass(by: task.classId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    classInfo
                    dueDateInfo
                    descriptionInfo
                    additionalInfo
                    actionButtons
                }
            }
            .frame(maxHeight: 560)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .matchedGeometryEffect(id: task.id, in: namespace, properties: .frame)
        )
        .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 12)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(task.priority.color)
                        .frame(width: 12, height: 12)

                    Text(task.priority.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(task.priority.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(task.priority.color.opacity(0.2)))
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color(.tertiarySystemGroupedBackground)))
                }
                .buttonStyle(.plain)
            }

            Text(task.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var classInfo: some View {
        if let classItem {
            HStack {
                Circle()
                    .fill(classItem.color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "book.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(classItem.name)
                        .font(.headline)
                    Text(classItem.professor)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Sem \(classItem.semester)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(classItem.color.opacity(0.18)))
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemGroupedBackground)))
        }
    }

    private var dueDateInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fecha de Entrega")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 18) {
                infoColumn(title: "Fecha", value: task.dueDate.formatted(date: .long, time: .omitted))

                Divider()
                    .frame(height: 38)

                infoColumn(title: "Hora", value: task.dueDate.formatted(date: .omitted, time: .shortened))

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Estado")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if task.dueDate < Date() {
                        Text("Vencida")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.red)
                    } else {
                        CountdownView(date: task.dueDate)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(task.timeStatus.color)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemGroupedBackground)))
    }

    @ViewBuilder
    private var descriptionInfo: some View {
        if !task.description.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Descripción")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text(task.description)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemGroupedBackground)))
        }
    }

    private var additionalInfo: some View {
        VStack(spacing: 12) {
            row(icon: "square.and.pencil", color: task.isPhysical ? .orange : .blue, title: "Tipo", value: task.isPhysical ? "Presencial" : "Digital")
            row(icon: "bell", color: .purple, title: "Recordatorio", value: reminderText)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemGroupedBackground)))
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: onComplete) {
                actionLabel("Marcar como Completada", icon: "checkmark.circle.fill")
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.green)
            .cornerRadius(12)

            Button(action: onEdit) {
                actionLabel("Editar Tarea", icon: "pencil")
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)

            Button(action: onDelete) {
                actionLabel("Eliminar Tarea", icon: "trash")
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.red)
            .cornerRadius(12)
        }
    }

    private var reminderText: String {
        if let notificationDate = task.notificationDate {
            return notificationDate.formatted(date: .abbreviated, time: .shortened)
        }

        if let hoursBefore = task.notificationHoursBefore {
            return "\(hoursBefore) horas antes"
        }

        return "Sin recordatorio"
    }

    private func infoColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body.weight(.medium))
        }
    }

    private func row(icon: String, color: Color, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }

    private func actionLabel(_ title: String, icon: String) -> some View {
        HStack {
            Spacer()
            Image(systemName: icon)
            Text(title)
                .fontWeight(.semibold)
            Spacer()
        }
    }
}
