//
//  TaskFormView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct TaskFormView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.dismiss) var dismiss
    
    let classId: UUID
    var editingTask: TaskItem?
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var priority: TaskPriority = .medium
    @State private var notificationHours: Int?
    @State private var isPhysical = false
    @State private var showingDatePicker = false
    
    let notificationOptions = [1, 2, 6, 12, 24, 48]
    
    init(classId: UUID, editingTask: TaskItem? = nil) {
        self.classId = classId
        self.editingTask = editingTask
        
        if let task = editingTask {
            _title = State(initialValue: task.title)
            _description = State(initialValue: task.description)
            _dueDate = State(initialValue: task.dueDate)
            _priority = State(initialValue: task.priority)
            _notificationHours = State(initialValue: task.notificationHoursBefore)
            _isPhysical = State(initialValue: task.isPhysical)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información de la Tarea")) {
                    TextField("Nombre de la tarea", text: $title)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Descripción (opcional)")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }
                }
                
                Section(header: Text("Fecha y Hora de Entrega")) {
                    HStack {
                        Text("Fecha")
                        Spacer()
                        Button(action: { showingDatePicker.toggle() }) {
                            HStack {
                                Text(dueDate.formatted(date: .long, time: .omitted))
                                Image(systemName: "calendar")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("Hora")
                        Spacer()
                        DatePicker("", selection: $dueDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    if showingDatePicker {
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                    }
                }
                
                Section(header: Text("Configuración")) {
                    Picker("Prioridad", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Label(priority.rawValue, systemImage: priority.icon)
                                .tag(priority)
                        }
                    }
                    
                    Toggle("Entrega Presencial", isOn: $isPhysical)
                    
                    Picker("Notificar antes", selection: $notificationHours.animation()) {
                        Text("No notificar").tag(nil as Int?)
                        ForEach(notificationOptions, id: \.self) { hours in
                            Text("\(hours) horas antes").tag(hours as Int?)
                        }
                    }
                }
                
                Section {
                    Button(action: saveTask) {
                        HStack {
                            Spacer()
                            Image(systemName: editingTask == nil ? "plus.circle.fill" : "checkmark.circle.fill")
                            Text(editingTask == nil ? "Crear Tarea" : "Actualizar Tarea")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle(editingTask == nil ? "Nueva Tarea" : "Editar Tarea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveTask() {
        let task: TaskItem
        
        if let editingTask = editingTask {
            task = TaskItem(
                id: editingTask.id,
                classId: editingTask.classId,
                title: title,
                description: description,
                dueDate: dueDate,
                priority: priority,
                notificationHoursBefore: notificationHours,
                isPhysical: isPhysical,
                isCompleted: editingTask.isCompleted
            )
            taskStore.updateTask(task)
        } else {
            task = TaskItem(
                classId: classId,
                title: title,
                description: description,
                dueDate: dueDate,
                priority: priority,
                notificationHoursBefore: notificationHours,
                isPhysical: isPhysical
            )
            taskStore.addTask(task)
        }
        
        NotificationManager.shared.scheduleTaskNotification(for: task)
        
        dismiss()
    }
}
