//
//  ReminderFormView.swift
//  UniversityManager
//

import SwiftUI

struct ReminderFormView: View {
    private enum ReminderMode: String, CaseIterable {
        case none = "No notificar"
        case relative = "Horas antes"
        case custom = "Día y hora específicos"
    }

    @EnvironmentObject var reminderStore: ReminderStore
    @EnvironmentObject var classStore: ClassStore
    @Environment(\.dismiss) var dismiss

    var editingReminder: AcademicReminder?

    @State private var title = ""
    @State private var description = ""
    @State private var eventDate = Date()
    @State private var location = ""
    @State private var priority: TaskPriority = .medium
    @State private var selectedClassId: UUID?
    @State private var notificationHours: Int?
    @State private var notificationDate = Date()
    @State private var reminderMode: ReminderMode = .none
    @State private var showingDatePicker = false

    private let notificationOptions = [1, 2, 6, 12, 24, 48]

    init(editingReminder: AcademicReminder? = nil) {
        self.editingReminder = editingReminder

        if let reminder = editingReminder {
            _title = State(initialValue: reminder.title)
            _description = State(initialValue: reminder.description)
            _eventDate = State(initialValue: reminder.eventDate)
            _location = State(initialValue: reminder.location ?? "")
            _priority = State(initialValue: reminder.priority)
            _selectedClassId = State(initialValue: reminder.classId)
            _notificationHours = State(initialValue: reminder.notificationHoursBefore)
            _notificationDate = State(initialValue: reminder.notificationDate ?? Self.defaultNotificationDate(for: reminder.eventDate))
            _reminderMode = State(initialValue: Self.initialReminderMode(for: reminder))
        } else {
            let defaultDate = Date()
            _notificationDate = State(initialValue: Self.defaultNotificationDate(for: defaultDate))
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información del Recordatorio")) {
                    TextField("Nombre", text: $title)

                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Descripción (opcional)")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }

                        TextEditor(text: $description)
                            .frame(minHeight: 92)
                    }

                    TextField("Lugar o nota corta (opcional)", text: $location)
                }

                Section(header: Text("Clase Opcional")) {
                    Picker("Relacionado con", selection: $selectedClassId) {
                        Text("Sin clase").tag(nil as UUID?)

                        ForEach(sortedClasses) { classItem in
                            Text(classItem.name).tag(Optional(classItem.id))
                        }
                    }
                }

                Section(header: Text("Fecha y Hora del Evento")) {
                    HStack {
                        Text("Fecha")
                        Spacer()
                        Button {
                            showingDatePicker.toggle()
                        } label: {
                            HStack {
                                Text(eventDate.formatted(date: .long, time: .omitted))
                                Image(systemName: "calendar")
                            }
                            .foregroundColor(.blue)
                        }
                    }

                    HStack {
                        Text("Hora")
                        Spacer()
                        DatePicker("", selection: $eventDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

                    if showingDatePicker {
                        DatePicker("", selection: $eventDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                    }
                }

                Section(header: Text("Configuración")) {
                    Picker("Importancia", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Label(priority.rawValue, systemImage: priority.icon)
                                .tag(priority)
                        }
                    }

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
                    Button(action: saveReminder) {
                        HStack {
                            Spacer()
                            Image(systemName: editingReminder == nil ? "plus.circle.fill" : "checkmark.circle.fill")
                            Text(editingReminder == nil ? "Crear Recordatorio" : "Actualizar Recordatorio")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(editingReminder == nil ? "Nuevo Recordatorio" : "Editar Recordatorio")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: eventDate) { _, newDate in
                guard reminderMode == .custom else { return }
                notificationDate = clampedReminderDate(notificationDate, eventDate: newDate)
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

    private var sortedClasses: [UniversityClass] {
        classStore.classes
            .sorted {
                if $0.semester != $1.semester {
                    return $0.semester < $1.semester
                }

                return $0.name < $1.name
            }
    }

    private var reminderDateRange: ClosedRange<Date> {
        let now = Date()
        let upperBound = eventDate > now ? eventDate : now
        return now...upperBound
    }

    private func saveReminder() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedNotificationHours = reminderMode == .relative ? notificationHours : nil
        let selectedNotificationDate = reminderMode == .custom ? clampedReminderDate(notificationDate, eventDate: eventDate) : nil

        let reminder: AcademicReminder

        if let editingReminder {
            reminder = AcademicReminder(
                id: editingReminder.id,
                classId: selectedClassId,
                title: cleanTitle,
                description: description,
                eventDate: eventDate,
                location: cleanLocation.isEmpty ? nil : cleanLocation,
                priority: priority,
                notificationHoursBefore: selectedNotificationHours,
                notificationDate: selectedNotificationDate,
                isCompleted: editingReminder.isCompleted,
                createdAt: editingReminder.createdAt
            )
            reminderStore.updateReminder(reminder)
        } else {
            reminder = AcademicReminder(
                classId: selectedClassId,
                title: cleanTitle,
                description: description,
                eventDate: eventDate,
                location: cleanLocation.isEmpty ? nil : cleanLocation,
                priority: priority,
                notificationHoursBefore: selectedNotificationHours,
                notificationDate: selectedNotificationDate
            )
            reminderStore.addReminder(reminder)
        }

        dismiss()
    }

    private static func defaultNotificationDate(for eventDate: Date) -> Date {
        let fallbackDate = eventDate.addingTimeInterval(-3600)
        return fallbackDate > Date() ? fallbackDate : Date()
    }

    private static func initialReminderMode(for reminder: AcademicReminder) -> ReminderMode {
        if reminder.notificationDate != nil {
            return .custom
        }

        if reminder.notificationHoursBefore != nil {
            return .relative
        }

        return .none
    }

    private func clampedReminderDate(_ date: Date, eventDate: Date) -> Date {
        let now = Date()

        if date < now {
            return now
        }

        if eventDate > now && date > eventDate {
            return eventDate
        }

        return date
    }

    private func preferredCustomNotificationDate() -> Date {
        if editingReminder?.notificationDate == nil && notificationDate.timeIntervalSinceNow < 60 {
            return clampedReminderDate(Self.defaultNotificationDate(for: eventDate), eventDate: eventDate)
        }

        return clampedReminderDate(notificationDate, eventDate: eventDate)
    }
}
