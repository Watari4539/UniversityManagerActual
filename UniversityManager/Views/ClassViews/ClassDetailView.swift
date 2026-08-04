//
//  ClassDetailView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct ClassDetailView: View {
    let classItem: UniversityClass
    @EnvironmentObject var classStore: ClassStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var examStore: ExamStore
    @EnvironmentObject var gradeStore: GradeStore
    @Environment(\.dismiss) var dismiss
    @State private var showingEditClass = false
    @State private var showingNewTask = false
    @State private var showingNewExam = false
    @State private var showingGrades = false
    @State private var showingDeleteAlert = false
    @State private var selectedTab = 0
    
    var tasks: [TaskItem] {
        taskStore.tasksForClass(classItem.id)
    }
    
    var exams: [Exam] {
        examStore.examsForClass(classItem.id)
    }
    
    var pendingTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted && $0.dueDate > Date() }
    }
    
    var completedTasks: [TaskItem] {
        tasks.filter { $0.isCompleted }
    }
    
    var upcomingExams: [Exam] {
        exams.filter { !$0.isCompleted && $0.date > Date() }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Circle()
                        .fill(classItem.color)
                        .frame(width: 80, height: 80)
                        
                    
                    VStack(spacing: 8) {
                        Text(classItem.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(classItem.professor)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // Action Buttons
                HStack(spacing: 16) {
                    ActionButton(
                        icon: "plus.circle.fill",
                        label: "Nueva Tarea",
                        color: .blue
                    ) {
                        showingNewTask = true
                    }
                    
                    ActionButton(
                        icon: "doc.badge.plus",
                        label: "Nuevo Examen",
                        color: .orange
                    ) {
                        showingNewExam = true
                    }
                }
                
                // Quick Stats
                HStack(spacing: 20) {
                    StatView(
                        icon: "checkmark.circle",
                        value: "\(completedTasks.count)",
                        label: "Completadas",
                        color: .green
                    )
                    
                    StatView(
                        icon: "clock",
                        value: "\(pendingTasks.count)",
                        label: "Pendientes",
                        color: .orange
                    )
                    
                    StatView(
                        icon: "doc.text",
                        value: "\(upcomingExams.count)",
                        label: "Exámenes",
                        color: .purple
                    )
                    
                    StatView(
                        icon: "number.circle",
                        value: "\(classItem.units)",
                        label: "Unidades",
                        color: .blue
                    )
                }
                .padding(.horizontal)
                
                // Tab Selector
                Picker("", selection: $selectedTab) {
                    Text("Tareas").tag(0)
                    Text("Exámenes").tag(1)
                    Text("Calificaciones").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Content based on tab - CORREGIDO: sin Group
                Group {
                    switch selectedTab {
                    case 0:
                        TasksSectionView(classItem: classItem)
                    case 1:
                        ExamsSectionView(classItem: classItem)
                    default:
                        GradesSectionView(classItem: classItem)
                    }
                }
                .padding(.horizontal)
                
                
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 70)
        }
        
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditClass = true
                    } label: {
                        Label("Editar Clase", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Eliminar Clase", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditClass) {
            ClassEditView(classItem: classItem)
        }
        .sheet(isPresented: $showingNewTask) {
            TaskFormView(classId: classItem.id)
        }
        .sheet(isPresented: $showingNewExam) {
            ExamFormView(classId: classItem.id)
        }
        .sheet(isPresented: $showingGrades) {
            GradeEditView(classItem: classItem)  // CORREGIDO: con parámetro
        }
        .alert("¿Eliminar esta clase?", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                deleteClass()
            }
        } message: {
            Text("Se eliminarán la clase, sus tareas, exámenes y calificaciones asociadas. Esta acción no se puede deshacer.")
        }
        .onReceive(classStore.$classes) { classes in
            if !classes.contains(where: { $0.id == classItem.id }) {
                dismiss()
            }
        }
    }
    
    private func deleteClass() {
        classStore.deleteClass(classItem)
        taskStore.deleteTasksForClass(classItem.id)
        examStore.deleteExamsForClass(classItem.id)
        gradeStore.deleteGradesForClass(classItem.id)
        dismiss()
    }
}

// MARK: - Subviews para ClassDetailView

private struct TasksSectionView: View {
    let classItem: UniversityClass
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var classStore: ClassStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tareas")
                .font(.title2)
                .fontWeight(.semibold)
            
            let pendingTasks = taskStore.tasksForClass(classItem.id)
                .filter { !$0.isCompleted }
                .sorted { $0.dueDate < $1.dueDate }
            
            if pendingTasks.isEmpty {
                EmptySectionView(
                    icon: "checkmark.circle",
                    message: "No hay tareas pendientes"
                )
                SectionLinkButton(title: "Ver todas", systemImage: "checklist") {
                    AllTasksView(classItem: classItem)
                }
            } else {
                ForEach(pendingTasks.prefix(3)) { task in
                    CompactTaskCard(task: task)
                }
                
                SectionLinkButton(title: "Ver todas", systemImage: "checklist") {
                    AllTasksView(classItem: classItem)
                }
                
            }
        }
    }
}

private struct ExamsSectionView: View {
    let classItem: UniversityClass
    @EnvironmentObject var examStore: ExamStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exámenes")
                .font(.title2)
                .fontWeight(.semibold)
            
            let upcomingExams = examStore.examsForClass(classItem.id)
                .filter { !$0.isCompleted && $0.date > Date() }
                .sorted { $0.date < $1.date }
            
            if upcomingExams.isEmpty {
                EmptySectionView(
                    icon: "doc.text",
                    message: "No hay exámenes próximos"
                )
                SectionLinkButton(title: "Ver todos", systemImage: "doc.text") {
                    AllExamsView(classItem: classItem)
                }

            } else {
                ForEach(upcomingExams.prefix(3)) { exam in
                    CompactExamCard(exam: exam)
                }
                SectionLinkButton(title: "Ver todos", systemImage: "doc.text") {
                    AllExamsView(classItem: classItem)
                }
                
            }
        }
    }
}

private struct ScheduleSectionView: View {
    let classItem: UniversityClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Horario")
                .font(.title2)
                .fontWeight(.semibold)
            
            if classItem.schedule.isEmpty {
                EmptySectionView(
                    icon: "calendar.badge.exclamationmark",
                    message: "No hay horario configurado"
                )
            } else {
                ForEach(classItem.schedule.sorted(by: { $0.weekday.rawValue < $1.weekday.rawValue })) { slot in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(slot.weekday.name)
                                .font(.headline)
                            Text("\(slot.startTime) - \(slot.endTime)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(slot.room)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(classItem.color.opacity(0.2))
                            )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                }
            }
        }
    }
}

private struct StatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct EmptySectionView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.5))
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

private struct SectionLinkButton<Destination: View>: View {
    let title: String
    let systemImage: String
    let destination: Destination
    
    init(title: String, systemImage: String, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.systemImage = systemImage
        self.destination = destination()
    }
    
    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 12) {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.14))
                    )
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.blue.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.blue.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CompactTaskCard: View {
    let task: TaskItem
    @EnvironmentObject var classStore: ClassStore
    
    var body: some View {
        HStack {
            Circle()
                .fill(task.priority.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(task.dueDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(task.timeStatus.color)
            }
            
            Spacer()
            
            Text(task.isPhysical ? "Presencial" : "Digital")
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
}

private struct CompactExamCard: View {
    let exam: Exam
    @EnvironmentObject var classStore: ClassStore
    
    var body: some View {
        HStack {
            Circle()
                .fill(exam.priority.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exam.title)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(exam.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(exam.timeStatus.color)
            }
            
            Spacer()
            
            if !exam.topics.isEmpty {
                Text("\(exam.topics.count) temas")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}
