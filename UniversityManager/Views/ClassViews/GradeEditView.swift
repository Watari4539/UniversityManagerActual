//
//  GradeEditView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct GradeEditView: View {
    let classItem: UniversityClass
    let unit: Int?
    
    @EnvironmentObject var gradeStore: GradeStore
    @Environment(\.dismiss) var dismiss
    
    @State private var score = ""
    @State private var notes = ""
    @State private var selectedUnit = 1
    
    // Calificación existente (si estamos editando)
    private var existingGrade: Grade? {
        gradeStore.gradeForClassAndUnit(classItem.id, unit: selectedUnit)
    }
    
    private var isUnitLocked: Bool {
        unit != nil
    }
    
    init(classItem: UniversityClass, unit: Int? = nil) {
        self.classItem = classItem
        self.unit = unit
        
        if let unit = unit {
            _selectedUnit = State(initialValue: unit)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Unidad")) {
                    Picker("Seleccionar Unidad", selection: $selectedUnit) {
                        ForEach(1...classItem.units, id: \.self) { unit in
                            Text("Unidad \(unit)").tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(isUnitLocked)
                }
                
                Section(header: Text("Calificación")) {
                    HStack {
                        Text("Puntaje")
                        Spacer()
                        TextField("0-100", text: $score)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("/ 100")
                            .foregroundColor(.secondary)
                    }
                    
                    // Mostrar porcentaje en tiempo real
                    
                }
                
                Section(header: Text("Notas")) {
                    TextField("", text: $notes)
                }
                
                Section {
                    Button(action: saveGrade) {
                        HStack {
                            Spacer()
                            Image(systemName: existingGrade == nil ? "plus.circle.fill" : "checkmark.circle.fill")
                            Text(existingGrade == nil ? "Guardar Calificación" : "Actualizar Calificación")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(score.isEmpty || Double(score) == nil)
                    
                    if existingGrade != nil {
                        Button(role: .destructive, action: deleteGrade) {
                            HStack {
                                Spacer()
                                Image(systemName: "trash.fill")
                                Text("Eliminar Calificación")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(existingGrade == nil ? "Nueva Calificación" : "Editar Calificación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadGradeForSelectedUnit()
            }
            .onChange(of: selectedUnit) { _ in
                loadGradeForSelectedUnit()
            }
        }
    }
    
    private func loadGradeForSelectedUnit() {
        if let grade = existingGrade {
            score = String(format: "%.1f", grade.score)
            notes = grade.notes ?? ""
        } else {
            score = ""
            notes = ""
        }
    }
    
    private func saveGrade() {
        guard let scoreValue = Double(score) else { return }
        
        let grade = Grade(
            id: existingGrade?.id ?? UUID(),
            classId: classItem.id,
            unit: selectedUnit,
            score: scoreValue,
            maxScore: 100, 
            dateRecorded: Date(),
            notes: notes.isEmpty ? nil : notes
        )
        
        gradeStore.addOrUpdateGrade(grade)
        dismiss()
    }
    
    private func deleteGrade() {
        if let grade = existingGrade {
            gradeStore.deleteGrade(grade)
        }
        dismiss()
    }
    
    private func letterGrade(for score: Double) -> String {
        switch score {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }
}
