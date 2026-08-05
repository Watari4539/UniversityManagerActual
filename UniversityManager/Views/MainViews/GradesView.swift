import SwiftUI

struct GradesView: View {
    @EnvironmentObject var classStore: ClassStore
    @EnvironmentObject var gradeStore: GradeStore
    @State private var showingSemesterMenu = false
    
    var filteredClasses: [UniversityClass] {
        classStore.classes.filter { $0.semester == classStore.currentSemester }
            .sorted { $0.name < $1.name }
    }
    
    var semesterAverage: Double {
        let classAverages = filteredClasses.map { gradeStore.averageForClass($0.id) }
        let validAverages = classAverages.filter { $0 > 0 }
        
        guard !validAverages.isEmpty else { return 0 }
        return validAverages.reduce(0, +) / Double(validAverages.count)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Semestre \(String(classStore.currentSemester))")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if semesterAverage > 0 {
                        VStack(spacing: 8) {
                            Text("Promedio del Semestre")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(String(format: "%.1f", semesterAverage))
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                
                                Text("/100")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                
                // Selector de semestre
                HStack {
                    Button(action: { showingSemesterMenu = true }) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Cambiar Semestre")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    Text("\(filteredClasses.count) materias")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                if filteredClasses.isEmpty {
                    // Estado vacío
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.4))
                        
                        Text("Sin materias en Semestre \(classStore.currentSemester)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    // Tabla simplificada
                    GradesTableView(
                        classes: filteredClasses,
                        gradeStore: gradeStore
                    )
                }
            }
            .navigationTitle("Calificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSemesterMenu) {
                SemesterPickerView()
            }
            .onReceive(gradeStore.$grades) { _ in
                        // Esto fuerza a que la vista se actualice cuando cambien las calificaciones
                        // No necesitamos hacer nada, solo recibir el cambio
            }
        }
    }
}

// Tabla simplificada
struct GradesTableView: View {
    let classes: [UniversityClass]
    @ObservedObject var gradeStore: GradeStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(classes) { classItem in
                    ClassGradesRow(
                        classItem: classItem,
                        gradeStore: gradeStore
                    )
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 70)
        }
    }
}

// Fila de calificaciones por materia
struct ClassGradesRow: View {
    let classItem: UniversityClass
    @ObservedObject var gradeStore: GradeStore
    
    var average: Double {
        gradeStore.averageForClass(classItem.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Encabezado de materia
            HStack {
                Circle()
                    .fill(classItem.color)
                    .frame(width: 12, height: 12)
                
                Text(classItem.name)
                    .font(.headline)
                
                Spacer()
                
                if average > 0 {
                    Text(String(format: "%.1f", average))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getGradeColor(for: average))
                }
            }
            
            // Unidades
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(1...classItem.units, id: \.self) { unit in
                        UnitGradeView(
                            classId: classItem.id,
                            unit: unit,
                            gradeStore: gradeStore
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// Vista de unidad individual
struct UnitGradeView: View {
    let classId: UUID
    let unit: Int
    let gradeStore: GradeStore
    
    var grade: Grade? {
        gradeStore.gradeForClassAndUnit(classId, unit: unit)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("U\(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if let grade = grade, grade.score > 0 {
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", grade.score))
                        .font(.system(size: 14, weight: .semibold))
 
                }
            } else {
                Text("-")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 60, height: 60)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

// Picker de semestre (igual que antes)
struct SemesterPickerView: View {
    @EnvironmentObject var classStore: ClassStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(classStore.availableSemesters, id: \.self) { semester in
                    Button(action: {
                        classStore.setCurrentSemester(semester)
                        dismiss()
                    }) {
                        HStack {
                            Text("Semestre \(semester)")
                            
                            Spacer()
                            
                            if classStore.currentSemester == semester {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Seleccionar Semestre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
