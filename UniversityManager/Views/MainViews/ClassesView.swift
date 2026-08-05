import SwiftUI

struct ClassesView: View {
    let resetToken: UUID
    @EnvironmentObject var classStore: ClassStore
    
    @State private var showingNewClass = false
    @State private var showingSemesterPicker = false
    
    // Filtramos usando el semestre global del Store
    var filteredClasses: [UniversityClass] {
        classStore.classes.filter { $0.semester == classStore.currentSemester }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // ENCABEZADO
                    VStack(spacing: 12) {
                        HStack {
                            Text("Clases")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            // Botón de Semestre
                            Button(action: { showingSemesterPicker = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.caption)
                                    Text("Sem \(classStore.currentSemester)")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.blue))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        Text("\(filteredClasses.count) materias registradas")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            // BOTÓN ESTILO "DASHED CARD"
                            Button(action: { showingNewClass = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Agregar Clase")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        Text("Toca para registrar una materia")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 18)
                                .frame(maxWidth: .infinity)
                                .frame(height: 78)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [7]))
                                        .foregroundColor(.blue.opacity(0.4))
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.blue.opacity(0.02))
                                )
                            }
                            .padding(.top, 4)

                            // LISTA DE CLASES FILTRADAS
                            ForEach(filteredClasses) { classItem in
                                NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                                    ClassCard(classItem: classItem) // Asegúrate de tener este componente
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 70)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewClass) {
                ClassFormView()
            }
            .sheet(isPresented: $showingSemesterPicker) {
                SemesterPickerSheet()
            }
        }
        .id(resetToken)
    }
}

struct SemesterPickerSheet: View {
    @EnvironmentObject var classStore: ClassStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var examStore: ExamStore
    @EnvironmentObject var gradeStore: GradeStore
    @Environment(\.dismiss) var dismiss
    @State private var semesterPendingDeletion: Int?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Seleccionar Semestre")) {
                    ForEach(classStore.availableSemesters, id: \.self) { semester in
                        Button(action: {
                            classStore.setCurrentSemester(semester)
                        }) {
                            HStack {
                                Text("Semestre \(semester)")
                                    .foregroundColor(.primary)
                                Spacer()
                                if classStore.currentSemester == semester {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                semesterPendingDeletion = semester
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                            .disabled(classStore.availableSemesters.count == 1)
                        }
                    }
                }

                Section {
                    Button(action: classStore.addSemester) {
                        Label("Agregar Semestre", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Cambiar Semestre")
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                "¿Eliminar Semestre \(semesterPendingDeletion ?? 0)?",
                isPresented: Binding(
                    get: { semesterPendingDeletion != nil },
                    set: { if !$0 { semesterPendingDeletion = nil } }
                )
            ) {
                Button("Cancelar", role: .cancel) {
                    semesterPendingDeletion = nil
                }
                Button("Eliminar", role: .destructive) {
                    deletePendingSemester()
                }
            } message: {
                Text(deleteConfirmationMessage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var deleteConfirmationMessage: String {
        guard let semester = semesterPendingDeletion else { return "" }
        let classCount = classStore.classes(for: semester).count

        if classCount == 0 {
            return "Esta acción eliminará el semestre del selector. No se puede deshacer."
        }

        return "Esta acción eliminará \(classCount) clase(s) de este semestre, junto con sus tareas, exámenes y calificaciones. No se puede deshacer."
    }

    private func deletePendingSemester() {
        guard let semester = semesterPendingDeletion else { return }
        let classesToDelete = classStore.classes(for: semester)

        for classItem in classesToDelete {
            taskStore.deleteTasksForClass(classItem.id)
            examStore.deleteExamsForClass(classItem.id)
            gradeStore.deleteGradesForClass(classItem.id)
        }

        classStore.deleteSemester(semester)
        semesterPendingDeletion = nil
    }
}
