import SwiftUI

struct TaskDetailView: View {
    let task: TaskItem
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var classStore: ClassStore
    @Environment(\.dismiss) var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(task.priority.color)
                                .frame(width: 12, height: 12)
                            
                            Text(task.priority.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(task.priority.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(task.priority.color.opacity(0.2))
                                )
                            
                            Spacer()
                            
                            if task.isCompleted {
                                Label("Completada", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Text(task.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Class Info
                    if let classItem = classStore.findClass(by: task.classId) {
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
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
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
                        .padding(.horizontal)
                    }
                    
                    // Due Date Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fecha de Entrega")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Fecha")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(task.dueDate.formatted(date: .long, time: .omitted))
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hora")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(task.dueDate.formatted(date: .omitted, time: .shortened))
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Estado")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if task.isCompleted {
                                    Text("Completada")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                } else if task.dueDate < Date() {
                                    Text("Vencida")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                } else {
                                    Text(timeRemainingString(from: task.dueDate))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(task.timeStatus.color)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                    
                    // Description
                    if !task.description.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Descripción")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(task.description)
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal)
                    }
                    
                    // Additional Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Información Adicional")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(task.isPhysical ? .orange : .blue)
                                .frame(width: 30)
                            
                            Text("Tipo de entrega")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(task.isPhysical ? "Presencial" : "Digital")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        if task.notificationDate != nil || task.notificationHoursBefore != nil {
                            HStack {
                                Image(systemName: "bell")
                                    .foregroundColor(.purple)
                                    .frame(width: 30)
                                
                                Text("Recordatorio")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(reminderText)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            
                            Text("Creada")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(task.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                    
                    // Action Buttons - VERSIÓN FUNCIONAL
                    VStack(spacing: 12) {
                        if !task.isCompleted {
                            Button(action: {
                                taskStore.markAsCompleted(task)
                                dismiss()
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Marcar como Completada")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }
                        
                        Button(action: {
                            showingEdit = true
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "pencil")
                                Text("Editar Tarea")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                Text("Eliminar Tarea")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .alert("¿Eliminar esta tarea?", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Eliminar", role: .destructive) {
                    taskStore.deleteTask(task)
                    dismiss()
                }
            } message: {
                Text("Esta acción no se puede deshacer. La tarea se eliminará permanentemente y no se mostrara en esta clase.")
            }
            .sheet(isPresented: $showingEdit) {
                TaskFormView(classId: task.classId, editingTask: task)
            }
        }
    }
    
    private func timeRemainingString(from date: Date) -> String {
        let totalSeconds = Int(max(0, date.timeIntervalSinceNow))
        
        if totalSeconds < 60 {
            return "\(totalSeconds) segundos"
        } else if totalSeconds < 3600 {
            let minutes = totalSeconds / 60
            return "\(minutes) minuto\(minutes != 1 ? "s" : "")"
        } else if totalSeconds < 86400 {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            return "\(hours)h \(minutes)m"
        } else {
            let days = totalSeconds / 86400
            let hours = (totalSeconds % 86400) / 3600
            return "\(days)d \(hours)h"
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
}
