//
//  GradesSectionView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 13/01/26.
//

import SwiftUI

struct GradesSectionView: View {
    let classItem: UniversityClass
    @EnvironmentObject var gradeStore: GradeStore
    @State private var showingAddGrade = false
    
    var grades: [Grade] {
        gradeStore.gradesForClass(classItem.id)
    }
    
    var average: Double {
        gradeStore.averageForClass(classItem.id)
    }
    
    private var hasRecordedGrades: Bool {
        grades.contains { $0.score > 0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header con promedio
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Calificaciones")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if average > 0 {
                        VStack(alignment: .trailing) {
                            Text("Promedio")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", average))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(gradeColor(for: average))
                        }
                    }
                }
                
                Button(action: { showingAddGrade = true }) {
                    Label(
                        hasRecordedGrades ? "Agregar Calificación" : "Agregar Primera Calificación",
                        systemImage: "plus.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            
            if !hasRecordedGrades {
                // Estado vacío
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.4))
                    
                    Text("Sin calificaciones registradas")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Lista de unidades con calificaciones
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(1...classItem.units, id: \.self) { unit in
                            UnitGradeCard(
                                classItem: classItem,
                                unit: unit
                            )
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddGrade) {
            GradeEditView(classItem: classItem)
        }
    }
}

struct UnitGradeCard: View {
    let classItem: UniversityClass
    let unit: Int
    
    @EnvironmentObject var gradeStore: GradeStore
    
    var grade: Grade? {
            gradeStore.gradeForClassAndUnit(classItem.id, unit: unit)
    }
    
    var body: some View {
        HStack {
            // Número de unidad
            VStack {
                Text("U\(unit)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Unidad")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(classItem.color.opacity(0.2))
            )
            
            // Información de calificación
            if let grade = grade, grade.score > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(String(format: "%.1f", grade.score))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("/ \(Int(grade.maxScore))")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f%%", grade.percentage))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(getGradeColor(for: grade.percentage))
                    }
                    
                    if let notes = grade.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.leading, 12)
            } else {
                VStack(alignment: .leading) {
                    Text("Sin calificar")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text("Usa el botón superior para agregarla")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 12)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// Función helper para colores de calificaciones
func gradeColor(for percentage: Double) -> Color {
    switch percentage {
    case 90...100: return .green
    case 80..<90: return .blue
    case 70..<80: return .orange
    default: return .red
    }
}

// Función helper para colores (la misma que usa GradesView)
func getGradeColor(for percentage: Double) -> Color {
    switch percentage {
    case 90...100: return .green
    case 80..<90: return .blue
    case 70..<80: return .orange
    default: return .red
    }
}
