//
//  TaskFormView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct TaskFormView: View {
    private enum ReminderMode: String, CaseIterable {
        case none = "No notificar"
        case relative = "Horas antes"
        case custom = "Día y hora específicos"
    }

    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var classStore: ClassStore
    @Environment(\.dismiss) var dismiss
    
    let classId: UUID?
    let allowsClassSelection: Bool
    var editingTask: TaskItem?
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var priority: TaskPriority = .medium
    @State private var notificationHours: Int?
    @State private var notificationDate = Date()
    @State private var reminderMode: ReminderMode = .none
    @State private var isPhysical = false
    @State private var showingDatePicker = false
    @State private var selectedClassId: UUID?
    
    let notificationOptions = [1, 2, 6, 12, 24, 48]
    
    init(classId: UUID? = nil, editingTask: TaskItem? = nil, allowsClassSelection: Bool = false) {
        self.classId = classId
        self.editingTask = editingTask
        self.allowsClassSelection = allowsClassSelection
        
        if let task = editingTask {
            _title = State(initialValue: task.title)
            _description = State(initialValue: task.description)
            _dueDate = State(initialValue: task.dueDate)
            _priority = State(initialValue: task.priority)
            _notificationHours = State(initialValue: task.notificationHoursBefore)
            _notificationDate = State(initialValue: task.notificationDate ?? Self.defaultNotificationDate(for: task.dueDate))
            _reminderMode = State(initialValue: Self.initialReminderMode(for: task))
            _isPhysical = State(initialValue: task.isPhysical)
            _selectedClassId = State(initialValue: task.classId)
        } else {
            let defaultDueDate = Date()
            _notificationDate = State(initialValue: Self.defaultNotificationDate(for: defaultDueDate))
            _selectedClassId = State(initialValue: classId)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                if allowsClassSelection {
                    Section(header: Text("Clase")) {
                        if classStore.classes.isEmpty {
                            Text("Crea una clase antes de agregar tareas")
                                .foregroundColor(.secondary)
                        } else {
                            Picker("Asignar a", selection: $selectedClassId) {
                                ForEach(sortedClasses) { classItem in
                                    Text(classItem.name).tag(Optional(classItem.id))
                                }
                            }
                        }
                    }
                }
                
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
                    
                    Picker("Recordatorio", selection: $reminderMode.animation()) {
                        ForEach(ReminderMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    if reminderMode == .relative {
                        Picker("Notificar antes", selection: $notificationHours.animation()) {
                            ForEach(notificationOptions, id: \.self) { hours in
                                Text("\(hours) horas antes").tag(hours as Int?)
                            }
                        }
                    }

                    if reminderMode == .custom {
                        DatePicker(
                            "Notificar el",
                            selection: $notificationDate,
                            in: reminderDateRange,
                            displayedComponents: [.date, .hourAndMinute]
                        )
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
                    .disabled(title.isEmpty || selectedClassId == nil)
                }
            }
            .navigationTitle(editingTask == nil ? "Nueva Tarea" : "Editar Tarea")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if selectedClassId == nil {
                    selectedClassId = sortedClasses.first?.id
                }
            }
            .onChange(of: dueDate) { _, newDate in
                guard reminderMode == .custom else { return }
                notificationDate = clampedReminderDate(notificationDate, dueDate: newDate)
            }
            .onChange(of: reminderMode) { _, newMode in
                if newMode == .relative && notificationHours == nil {
                    notificationHours = notificationOptions.first
                } else if newMode == .custom {
                    notificationDate = preferredCustomNotificationDate()
                }
            }
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
        guard let taskClassId = selectedClassId else { return }
        
        let task: TaskItem
        let selectedNotificationHours = reminderMode == .relative ? notificationHours : nil
        let selectedNotificationDate = reminderMode == .custom ? clampedReminderDate(notificationDate, dueDate: dueDate) : nil
        
        if let editingTask = editingTask {
            task = TaskItem(
                id: editingTask.id,
                classId: taskClassId,
                title: title,
                description: description,
                dueDate: dueDate,
                priority: priority,
                notificationHoursBefore: selectedNotificationHours,
                notificationDate: selectedNotificationDate,
                isPhysical: isPhysical,
                isCompleted: editingTask.isCompleted,
                createdAt: editingTask.createdAt
            )
            taskStore.updateTask(task)
        } else {
            task = TaskItem(
                classId: taskClassId,
                title: title,
                description: description,
                dueDate: dueDate,
                priority: priority,
                notificationHoursBefore: selectedNotificationHours,
                notificationDate: selectedNotificationDate,
                isPhysical: isPhysical
            )
            taskStore.addTask(task)
        }
        
        NotificationManager.shared.scheduleTaskNotification(for: task)
        
        dismiss()
    }
    
    private var sortedClasses: [UniversityClass] {
        classStore.classes.sorted { $0.name < $1.name }
    }

    private var reminderDateRange: ClosedRange<Date> {
        let now = Date()
        let upperBound = dueDate > now ? dueDate : now
        return now...upperBound
    }

    private static func defaultNotificationDate(for dueDate: Date) -> Date {
        let fallbackDate = dueDate.addingTimeInterval(-3600)
        return fallbackDate > Date() ? fallbackDate : Date()
    }

    private static func initialReminderMode(for task: TaskItem) -> ReminderMode {
        if task.notificationDate != nil {
            return .custom
        }

        if task.notificationHoursBefore != nil {
            return .relative
        }

        return .none
    }

    private func clampedReminderDate(_ date: Date, dueDate: Date) -> Date {
        let now = Date()

        if date < now {
            return now
        }

        if dueDate > now && date > dueDate {
            return dueDate
        }

        return date
    }

    private func preferredCustomNotificationDate() -> Date {
        if editingTask?.notificationDate == nil && notificationDate.timeIntervalSinceNow < 60 {
            return clampedReminderDate(Self.defaultNotificationDate(for: dueDate), dueDate: dueDate)
        }

        return clampedReminderDate(notificationDate, dueDate: dueDate)
    }
}
