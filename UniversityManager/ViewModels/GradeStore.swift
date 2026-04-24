//
//  GradeStore.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 13/01/26.
//

import SwiftUI
import Combine

class GradeStore: ObservableObject {
    @Published var grades: [Grade] = []
    
    private let saveKey = "savedGrades"
    
    init() {
        loadGrades()
    }
    
    // Agregar o actualizar calificación
    func addOrUpdateGrade(_ grade: Grade) {
        if let index = grades.firstIndex(where: {
            $0.classId == grade.classId && $0.unit == grade.unit
        }) {
            // Actualizar calificación existente
            grades[index] = grade
        } else {
            // Agregar nueva calificación
            grades.append(grade)
        }
        saveGrades()
    }
    
    // Obtener calificaciones de una clase
    func gradesForClass(_ classId: UUID) -> [Grade] {
        grades.filter { $0.classId == classId }
            .sorted { $0.unit < $1.unit }
    }
    
    // Obtener calificación específica de unidad
    func gradeForClassAndUnit(_ classId: UUID, unit: Int) -> Grade? {
        grades.first { $0.classId == classId && $0.unit == unit }
    }
    
    // Calcular promedio de una clase
    func averageForClass(_ classId: UUID) -> Double {
        let classGrades = gradesForClass(classId)
        let gradesWithScore = classGrades.filter { $0.score > 0 }
        
        guard !gradesWithScore.isEmpty else { return 0 }
        
        let total = gradesWithScore.reduce(0) { $0 + $1.percentage }
        return total / Double(gradesWithScore.count)
    }
    
    // Eliminar calificación
    func deleteGrade(_ grade: Grade) {
        grades.removeAll { $0.id == grade.id }
        saveGrades()
    }
    
    // Eliminar todas las calificaciones de una clase
    func deleteGradesForClass(_ classId: UUID) {
        grades.removeAll { $0.classId == classId }
        saveGrades()
    }
    
    private func saveGrades() {
        if let encoded = try? JSONEncoder().encode(grades) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadGrades() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Grade].self, from: data) else {
            return
        }
        grades = decoded
    }
}
