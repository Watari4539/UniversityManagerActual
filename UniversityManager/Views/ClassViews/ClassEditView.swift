//
//  ClassEditView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct ClassEditView: View {
    let classItem: UniversityClass
    @EnvironmentObject var classStore: ClassStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var examStore: ExamStore
    @EnvironmentObject var gradeStore: GradeStore
    @Environment(\.dismiss) var dismiss
    
    @State private var className: String
    @State private var professor: String
    @State private var group: String
    @State private var semester: Int
    @State private var units: Int
    @State private var room: String
    @State private var isExtra: Bool
    @State private var selectedColor: Color
    @State private var schedule: [ScheduleSlot]
    @State private var showingScheduleEditor = false
    @State private var scheduleSlotToEdit: ScheduleSlot?
    @State private var showingDeleteAlert = false
    
    // Colores predeterminados
    let presetColors: [(name: String, color: Color, hex: String)] = [
        ("", .blue, "#007AFF"),
        ("", Color(hex: "#FF6B6B"), "#FF6B6B"),
        ("", Color(hex: "#4ECDC4"), "#4ECDC4"),
        ("", Color(hex: "#FFD166"), "#FFD166"),
        ("", Color(hex: "#9D4EDD"), "#9D4EDD"),
        ("", Color(hex: "#F9A03F"), "#F9A03F"),
        ("", Color(hex: "#2A9D8F"), "#2A9D8F"),
        ("Michel", Color(hex: "#FF8FA3"), "#FF8FA3"),
        ("", Color(hex: "#6C91C2"), "#6C91C2"),
        ("", Color(hex: "#06D6A0"), "#06D6A0")
    ]
    
    init(classItem: UniversityClass) {
        self.classItem = classItem
        _className = State(initialValue: classItem.name)
        _professor = State(initialValue: classItem.professor)
        _group = State(initialValue: classItem.group ?? "")
        _semester = State(initialValue: classItem.semester)
        _units = State(initialValue: classItem.units)
        _room = State(initialValue: classItem.room)
        _isExtra = State(initialValue: classItem.isExtra)
        _selectedColor = State(initialValue: Color(hex: classItem.colorHex))
        _schedule = State(initialValue: classItem.schedule)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información Básica")) {
                    TextField("Nombre de la materia", text: $className)
                    
                    TextField("Nombre del profesor", text: $professor)

                    TextField("Grupo (opcional)", text: $group)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .onChange(of: group) { _, newValue in
                            group = sanitizedGroup(newValue)
                        }
                    
                    Picker("Semestre", selection: $semester) {
                        ForEach(classStore.availableSemesters, id: \.self) { num in
                            Text("Semestre \(num)").tag(num)
                        }
                    }
                    
                    Stepper("Unidades: \(units)", value: $units, in: 1...20)
                    
                    TextField("", text: $room)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    Toggle("Clase extra", isOn: $isExtra)

                    if isExtra {
                        Text("Las clases extra pueden tener calificaciones y promedio propio, pero no afectan el promedio general del semestre.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Color de la Materia")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(presetColors, id: \.hex) { preset in
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(preset.color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == preset.color ?
                                                       Color.blue : Color.clear, lineWidth: 3)
                                        )
                                        .onTapGesture {
                                            selectedColor = preset.color
                                        }
                                    
                                    Text(preset.name)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 60)
                            }

                            VStack(spacing: 6) {
                                ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                                    .labelsHidden()
                                    .frame(width: 40, height: 40)
                                    .scaleEffect(1.15)

                                Text("RGB")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 60)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Horario")) {
                    if schedule.isEmpty {
                        Text("No hay horarios configurados")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(schedule) { slot in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(slot.weekday.name)
                                        .font(.subheadline)
                                    Text("\(slot.startTime) - \(slot.endTime)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(slot.room)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.gray.opacity(0.2)))

                                Button(action: {
                                    scheduleSlotToEdit = slot
                                }) {
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.borderless)
                                
                                Button(action: {
                                    if let index = schedule.firstIndex(where: { $0.id == slot.id }) {
                                        schedule.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                scheduleSlotToEdit = slot
                            }
                        }
                    }
                    
                    Button(action: { showingScheduleEditor = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Agregar Horario")
                        }
                    }
                }
                
                Section {
                    Button(action: saveChanges) {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                            Text("Guardar Cambios")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(className.isEmpty || professor.isEmpty)
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        HStack {
                            Spacer()
                            Image(systemName: "trash.circle.fill")
                            Text("Eliminar Clase")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Editar Clase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .alert("¿Eliminar esta clase?", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Eliminar", role: .destructive) {
                    deleteClass()
                }
            } message: {
                Text("Esta acción eliminará la clase, sus tareas y exámenes. No se puede deshacer.")
            }
            .sheet(isPresented: $showingScheduleEditor) {
                ScheduleEditorView(schedule: $schedule, defaultRoom: room)
            }
            .sheet(item: $scheduleSlotToEdit) { slot in
                ScheduleEditorView(schedule: $schedule, defaultRoom: room, editingSlot: slot)
            }
        }
    }
    
    private func saveChanges() {
        let hexColor = selectedColor.toHex()
        
        // Crear clase actualizada SIN createdAt
        let updatedClass = UniversityClass(
            id: classItem.id,
            name: className,
            professor: professor,
            group: normalizedGroup,
            semester: semester,
            colorHex: hexColor,
            units: units,
            room: room,
            schedule: schedule,
            isExtra: isExtra,
            createdAt: classItem.createdAt
        )
        
        classStore.updateClass(updatedClass)
        dismiss()
    }
    
    private func deleteClass() {
        classStore.deleteClass(classItem)
        taskStore.deleteTasksForClass(classItem.id)
        examStore.deleteExamsForClass(classItem.id)
        gradeStore.deleteGradesForClass(classItem.id)
        dismiss()
    }

    private var normalizedGroup: String? {
        let trimmedGroup = group.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedGroup.isEmpty ? nil : trimmedGroup
    }

    private func sanitizedGroup(_ value: String) -> String {
        String(value.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
    }
}
