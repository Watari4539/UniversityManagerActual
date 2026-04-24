//
//  AllTasksView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct AllTasksView: View {
    let classItem: UniversityClass
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var classStore: ClassStore
    @Environment(\.dismiss) var dismiss
    @State private var showingNewTask = false
    @State private var showingTaskDetail: TaskItem?
    @State private var selectedFilter = 0 // 0: Todas, 1: Pendientes, 2: Completadas
    @State private var showingEditTask: TaskItem?
    
    var filteredTasks: [TaskItem] {
        let allTasks = taskStore.tasksForClass(classItem.id)
        
        switch selectedFilter {
        case 0: // Todas
            return allTasks.sorted { $0.dueDate < $1.dueDate }
        case 1: // Pendientes
            return allTasks
                .filter { !$0.isCompleted }
                .sorted { $0.dueDate < $1.dueDate }
        case 2: // Completadas
            return allTasks
                .filter { $0.isCompleted }
                .sorted { $0.dueDate > $1.dueDate } // Más recientes primero
        default:
            return allTasks
        }
    }
    
    var pendingCount: Int {
        taskStore.tasksForClass(classItem.id)
            .filter { !$0.isCompleted }
            .count
    }
    
    var completedCount: Int {
        taskStore.tasksForClass(classItem.id)
            .filter { $0.isCompleted }
            .count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Stats Bar
                    HStack(spacing: 20) {
                        StatBadge(
                            count: pendingCount,
                            label: "Pendientes",
                            color: .orange,
                            icon: "clock"
                        )
                        
                        StatBadge(
                            count: completedCount,
                            label: "Completadas",
                            color: .green,
                            icon: "checkmark.circle"
                        )
                        
                        StatBadge(
                            count: filteredTasks.count,
                            label: "Total",
                            color: .blue,
                            icon: "doc.text"
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    
                    // Filter Picker
                    Picker("Filtro", selection: $selectedFilter) {
                        Text("Todas").tag(0)
                        Text("Pendientes").tag(1)
                        Text("Completadas").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    
                    // Tasks List
                    if filteredTasks.isEmpty {
                        EmptyTasksView(filter: selectedFilter)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTasks) { task in
                                    ExtendedTaskCard(task: task)
                                        .contextMenu {
                                            Button {
                                                if task.isCompleted {
                                                    var updated = task
                                                    updated.isCompleted = false
                                                    taskStore.updateTask(updated)
                                                } else {
                                                    taskStore.markAsCompleted(task)
                                                }
                                            } label: {
                                                Label(
                                                    task.isCompleted ? "Marcar como pendiente" : "Marcar como completada",
                                                    systemImage: task.isCompleted ? "clock" : "checkmark"
                                                )
                                            }
                                            
                                            Button {
                                                showingEditTask = task
                                            } label: {
                                                Label("Editar", systemImage: "pencil")
                                            }
                                            
                                            Divider()
                                            
                                            Button(role: .destructive) {
                                                taskStore.deleteTask(task)
                                            } label: {
                                                Label("Eliminar", systemImage: "trash")
                                            }
                                        }
                                        .onTapGesture {
                                            showingTaskDetail = task
                                        }
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Tareas de \(classItem.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "")
                            Text("")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingNewTask) {
                TaskFormView(classId: classItem.id)
            }
            .sheet(item: $showingEditTask) { task in
                TaskFormView(classId: classItem.id, editingTask: task)
            }
            .sheet(item: $showingTaskDetail) { task in
                TaskDetailView(task: task)
            }
        }
    }
}

struct ExtendedTaskCard: View {
    let task: TaskItem
    @EnvironmentObject var classStore: ClassStore
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 10, height: 10)
                
                Text(task.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                // Status Badge
                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else if task.dueDate < Date() {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
            
            // Description Preview
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.leading, 14)
            }
            
            // Details Row
            HStack(spacing: 16) {
                // Due Date
                VStack(alignment: .leading, spacing: 2) {
                    Text("Entrega")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(task.dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                    }
                    .foregroundColor(task.timeStatus.color)
                }
                
                // Time
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hora")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(task.dueDate.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                // Type Badge
                Text(task.isPhysical ? "Presencial" : "Digital")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(task.isPhysical ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    )
                    .foregroundColor(task.isPhysical ? .orange : .blue)
            }
            .padding(.leading, 14)
            
            // Time Remaining
            if !task.isCompleted && task.dueDate > Date() {
                HStack {
                    Image(systemName: "hourglass")
                        .font(.caption2)
                    
                    CountdownView(date: task.dueDate)
                        .font(.caption)
                        .foregroundColor(task.timeStatus.color)
                    
                    Spacer()
                    
                    Text("\(task.priority.rawValue)")
                        .font(.caption2)
                        .foregroundColor(task.priority.color)
                }
                .padding(.leading, 14)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(task.isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
}

struct EmptyTasksView: View {
    let filter: Int
    
    var message: String {
        switch filter {
        case 0: return "No hay tareas registradas"
        case 1: return "¡Sos un crack pa! No tienes tareas pendientes "
        case 2: return "No hay tareas completadas"
        default: return "No hay tareas"
        }
    }
    
    var icon: String {
        switch filter {
        case 0: return "doc.text"
        case 1: return "checkmark.circle"
        case 2: return "clock"
        default: return "doc.text"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text(message)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


