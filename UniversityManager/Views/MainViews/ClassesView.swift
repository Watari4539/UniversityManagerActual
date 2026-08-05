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
    @State private var semesterEditingDates: SemesterInfo?
    @State private var newSemesterNumber = 1
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Seleccionar semestre")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .padding(.horizontal)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                        spacing: 10
                    ) {
                        ForEach(classStore.semesters) { semester in
                            SemesterCardView(
                                semester: semester,
                                isCurrent: classStore.currentSemester == semester.number
                            ) {
                                classStore.setCurrentSemester(semester.number)
                            } onEditDates: {
                                semesterEditingDates = semester
                            } onDelete: {
                                semesterPendingDeletion = semester.number
                            }
                            .contextMenu {
                                Button {
                                    semesterEditingDates = semester
                                } label: {
                                    Label("Editar fechas", systemImage: "calendar")
                                }

                                Button(role: .destructive) {
                                    semesterPendingDeletion = semester.number
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                                .disabled(classStore.availableSemesters.count == 1)
                            }
                        }
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Agregar semestre")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Stepper(
                            "Nuevo semestre: \(newSemesterNumber)",
                            value: $newSemesterNumber,
                            in: 1...99
                        )

                        Button(action: addSelectedSemester) {
                            Label("Agregar Semestre \(newSemesterNumber)", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(classStore.availableSemesters.contains(newSemesterNumber))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Cambiar Semestre")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                newSemesterNumber = classStore.suggestedNewSemester
            }
            .onChange(of: classStore.availableSemesters) { _, _ in
                if classStore.availableSemesters.contains(newSemesterNumber) {
                    newSemesterNumber = classStore.suggestedNewSemester
                }
            }
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
            .sheet(item: $semesterEditingDates) { semester in
                SemesterDateEditorView(
                    semester: semester,
                    isEndDateLocked: classStore.hasReviewedStats(for: semester.number)
                ) { startDate, endDate in
                    classStore.updateSemesterDates(
                        semester.number,
                        startDate: startDate,
                        endDate: endDate
                    )
                }
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

    private func addSelectedSemester() {
        classStore.addSemester(number: newSemesterNumber)
        newSemesterNumber = classStore.suggestedNewSemester
    }
}

private struct SemesterCardView: View {
    let semester: SemesterInfo
    let isCurrent: Bool
    let onSelect: () -> Void
    let onEditDates: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(semester.number)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Semestre")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }

                Spacer()

                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }

            Text(dateSummary)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Button(action: onEditDates) {
                    Image(systemName: "calendar")
                        .font(.caption.weight(.semibold))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Color.blue.opacity(0.12)))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Color.red.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCurrent ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrent ? Color.blue.opacity(0.45) : Color.clear, lineWidth: 1.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: onSelect)
    }

    private var dateSummary: String {
        let start = semester.startDate.map(shortDate) ?? "Sin inicio"
        let end = semester.endDate.map(shortDate) ?? "Sin fin"

        if semester.startDate == nil && semester.endDate == nil {
            return "Sin fechas"
        }

        return "\(start) - \(end)"
    }

    private func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year())
    }
}

private struct SemesterDateEditorView: View {
    let semester: SemesterInfo
    let isEndDateLocked: Bool
    let onSave: (Date?, Date?) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var hasStartDate: Bool
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date

    init(
        semester: SemesterInfo,
        isEndDateLocked: Bool = false,
        onSave: @escaping (Date?, Date?) -> Void
    ) {
        self.semester = semester
        self.isEndDateLocked = isEndDateLocked
        self.onSave = onSave

        _hasStartDate = State(initialValue: semester.startDate != nil)
        _startDate = State(initialValue: semester.startDate ?? Date())
        _hasEndDate = State(initialValue: semester.endDate != nil)
        _endDate = State(initialValue: semester.endDate ?? Date())
    }

    var body: some View {
        NavigationView {
            Form {
                if isEndDateLocked {
                    Section {
                        Label("Fecha de fin bloqueada", systemImage: "lock.fill")
                            .font(.headline)
                            .foregroundColor(.red)

                        Text("Las estadísticas de este semestre ya fueron revisadas. La fecha de fin ya no puede modificarse.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section(header: Text("Fechas del semestre")) {
                    Toggle("Fecha de inicio", isOn: $hasStartDate.animation())

                    if hasStartDate {
                        DatePicker(
                            "Inicio",
                            selection: $startDate,
                            displayedComponents: .date
                        )
                    }

                    Toggle("Fecha de fin", isOn: $hasEndDate.animation())
                        .disabled(isEndDateLocked)

                    if hasEndDate {
                        DatePicker(
                            "Fin",
                            selection: $endDate,
                            displayedComponents: .date
                        )
                        .disabled(isEndDateLocked)
                    }
                }

                Section {
                    Button {
                        onSave(
                            hasStartDate ? startDate : nil,
                            isEndDateLocked ? semester.endDate : (hasEndDate ? endDate : nil)
                        )
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                            Text("Guardar Fechas")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Semestre \(semester.number)")
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
}
