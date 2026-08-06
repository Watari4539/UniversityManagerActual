//
//  ClassCard.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct ClassCard: View {
    let classItem: UniversityClass
    @State private var isPressed = false
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var examStore: ExamStore
    
    var pendingTasks: Int {
        taskStore.tasksForClass(classItem.id)
            .filter { !$0.isCompleted && $0.dueDate > Date() }
            .count
    }
    
    var upcomingExams: Int {
        examStore.examsForClass(classItem.id)
            .filter { !$0.isCompleted && $0.date > Date() }
            .count
    }
    
    var body: some View {
        NavigationLink(destination: ClassDetailView(classItem: classItem)) {
            VStack(alignment: .leading, spacing: 12) {
                // Header - MEJORADO
                HStack {
                    Circle()
                        .fill(classItem.color)
                        .frame(width: 40, height: 40)
                        
                    
                    Spacer()
                    
                    // Badge de tareas pendientes - MEJOR VISIBILIDAD
                    if pendingTasks > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checklist")
                                .font(.caption2)
                            Text("\(pendingTasks)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(pendingTasks > 0 ? .red : .green)
                        )
                    }

                    if classItem.isExtra {
                        Text("Extra")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.orange.opacity(0.14)))
                    }
                }
                
                // Class Name - MEJOR TEXTO
                Text(classItem.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)  // ← Permite múltiples líneas
                
                // Professor
                Text(classItem.professor)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Info Row - REORGANIZADO
                HStack(spacing: 20) {
                    Label("\(classItem.units) u", systemImage: "number.circle")
                        .font(.caption)

                    if let group = classItem.group, !group.isEmpty {
                        Label(group, systemImage: "person.2")
                            .font(.caption)
                    }
                    
                    Label(classItem.room, systemImage: "mappin.circle")
                        .font(.caption)
                    
                    Spacer()
                    
                    if upcomingExams > 0 {
                        Label("\(upcomingExams) exámen", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct AddClassCard: View {
    // En AddClassCard.swift o dentro de ClassesView.swift
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Nueva Clase")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Agregar una nueva materia")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundColor(.blue.opacity(0.3))
        )
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
