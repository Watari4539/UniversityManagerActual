//
//  ClassFormView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct ClassFormView: View {
    @EnvironmentObject var classStore: ClassStore
    @Environment(\.dismiss) var dismiss
    @State private var className = ""
    @State private var professor = ""
    @State private var semester = 1
    @State private var units = 1
    @State private var room = ""
    @State private var selectedColor = Color.blue
    @State private var schedule: [ScheduleSlot] = []
    @State private var showingScheduleEditor = false
    @State private var didSetDefaultSemester = false
    
    let presetColors: [(name: String, color: Color, hex: String)] = [
        ("", .blue, "#007AFF"),
        ("", Color(hex: "#FF6B6B"), "#FF6B6B"),
        ("", Color(hex: "#4ECDC4"), "#4ECDC4"),
        ("", Color(hex: "#FFD166"), "#FFD166"),
        ("", Color(hex: "#9D4EDD"), "#9D4EDD"),
        ("", Color(hex: "#F9A03F"), "#F9A03F"),
        ("", Color(hex: "#2A9D8F"), "#2A9D8F"),
        ("", Color(hex: "#FF8FA3"), "#FF8FA3"),
        ("", Color(hex: "#6C91C2"), "#6C91C2"),
        ("", Color(hex: "#06D6A0"), "#06D6A0")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información Básica")) {
                    TextField("Nombre de la materia", text: $className)
                    
                    TextField("Nombre del profesor", text: $professor)
                    
                    Picker("Semestre", selection: $semester) {
                        ForEach(classStore.availableSemesters, id: \.self) { num in
                            Text("Semestre \(num)").tag(num)
                        }
                    }
                    
                    Stepper("Unidades: \(units)", value: $units, in: 1...10)
                    
                    TextField("Salón", text: $room)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
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
                            }
                        }
                        .onDelete { indices in
                            schedule.remove(atOffsets: indices)
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
                    Button(action: saveClass) {
                        HStack {
                            Spacer()
                            Text("Crear Clase")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(className.isEmpty || professor.isEmpty)
                }
            }
            .navigationTitle("Nueva Clase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingScheduleEditor) {
                ScheduleEditorView(schedule: $schedule, defaultRoom: room)
            }
            .onAppear {
                guard !didSetDefaultSemester else { return }
                semester = classStore.currentSemester
                didSetDefaultSemester = true
            }
        }
    }
    
    private func saveClass() {
        let hexColor = presetColors.first { $0.color == selectedColor }?.hex ?? "#007AFF"
        
        let newClass = UniversityClass(
            name: className,
            professor: professor,
            semester: semester,
            colorHex: hexColor,
            units: units,
            room: room,
            schedule: schedule
        )
        
        classStore.addClass(newClass)
        dismiss()
    }
}
