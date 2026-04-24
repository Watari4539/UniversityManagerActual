//
//  ExamFormView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct ExamFormView: View {
    @EnvironmentObject var examStore: ExamStore
    @Environment(\.dismiss) var dismiss
    
    let classId: UUID
    var editingExam: Exam?
    
    @State private var title = ""
    @State private var topics: [String] = []
    @State private var newTopic = ""
    @State private var date = Date()
    @State private var room = ""
    @State private var priority: TaskPriority = .medium
    @State private var notificationHours: Int?
    @State private var showingDatePicker = false
    
    let notificationOptions = [1, 2, 6, 12, 24, 48]
    
    init(classId: UUID, editingExam: Exam? = nil) {
        self.classId = classId
        self.editingExam = editingExam
        
        if let exam = editingExam {
            _title = State(initialValue: exam.title)
            _topics = State(initialValue: exam.topics)
            _date = State(initialValue: exam.date)
            _room = State(initialValue: exam.room ?? "")
            _priority = State(initialValue: exam.priority)
            _notificationHours = State(initialValue: exam.notificationHoursBefore)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información del Examen")) {
                    TextField("Nombre del examen", text: $title)
                }
                
                Section(header: Text("Temas a Evaluar")) {
                    ForEach(topics, id: \.self) { topic in
                        HStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 6, height: 6)
                            Text(topic)
                            Spacer()
                        }
                    }
                    .onDelete { indices in
                        topics.remove(atOffsets: indices)
                    }
                    
                    HStack {
                        TextField("Agregar tema", text: $newTopic)
                        
                        Button(action: addTopic) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newTopic.isEmpty)
                    }
                }
                
                Section(header: Text("Fecha y Hora")) {
                    HStack {
                        Text("Fecha")
                        Spacer()
                        Button(action: { showingDatePicker.toggle() }) {
                            HStack {
                                Text(date.formatted(date: .long, time: .omitted))
                                Image(systemName: "calendar")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("Hora")
                        Spacer()
                        DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    if showingDatePicker {
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .labelsHidden()
                    }
                    
                    TextField("Salón (opcional)", text: $room)
                        .textInputAutocapitalization(.characters)
                }
                
                Section(header: Text("Configuración")) {
                    Picker("Prioridad", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Label(priority.rawValue, systemImage: priority.icon)
                                .tag(priority)
                        }
                    }
                    
                    Picker("Notificar antes", selection: $notificationHours.animation()) {
                        Text("No notificar").tag(nil as Int?)
                        ForEach(notificationOptions, id: \.self) { hours in
                            Text("\(hours) horas antes").tag(hours as Int?)
                        }
                    }
                }
                
                Section {
                    Button(action: saveExam) {
                        HStack {
                            Spacer()
                            Image(systemName: editingExam == nil ? "plus.circle.fill" : "checkmark.circle.fill")
                            Text(editingExam == nil ? "Crear Examen" : "Actualizar Examen")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle(editingExam == nil ? "Nuevo Examen" : "Editar Examen")
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
    
    private func addTopic() {
        let trimmedTopic = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTopic.isEmpty {
            topics.append(trimmedTopic)
            newTopic = ""
        }
    }
    
    private func saveExam() {
        let exam: Exam
        
        if let editingExam = editingExam {
            exam = Exam(
                id: editingExam.id,
                classId: editingExam.classId,
                title: title,
                topics: topics,
                date: date,
                room: room.isEmpty ? nil : room,
                priority: priority,
                notificationHoursBefore: notificationHours,
                isCompleted: editingExam.isCompleted,
                createdAt: editingExam.createdAt
            )
            examStore.updateExam(exam)
        } else {
            exam = Exam(
                classId: classId,
                title: title,
                topics: topics,
                date: date,
                room: room.isEmpty ? nil : room,
                priority: priority,
                notificationHoursBefore: notificationHours
            )
            examStore.addExam(exam)
        }
        
        dismiss()
    }
}
