//
//  ProfessorsView.swift
//  UniversityManager
//

import SwiftUI

struct ProfessorsView: View {
    @EnvironmentObject var professorStore: ProfessorStore
    @State private var showingForm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if professorStore.professors.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(professorStore.sortedProfessors()) { professor in
                            NavigationLink {
                                ProfessorDetailView(professor: professor)
                            } label: {
                                ProfessorRowView(professor: professor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 96)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Profesores")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingForm = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            ProfessorFormView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Profesores")
                .font(.largeTitle.bold())

            Text("Guarda perfiles de tus maestros para reutilizarlos al crear clases y consultar tu historial con cada uno.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 42, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 82, height: 82)
                .background(Circle().fill(Color.blue.opacity(0.12)))

            Text("Sin profesores guardados")
                .font(.headline)

            Text("Crea perfiles con contacto, notas y detalles útiles para encontrarlos después al crear una clase.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct ProfessorRowView: View {
    let professor: ProfessorProfile

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 46, height: 46)
                .overlay(
                    Text(initials)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(professor.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                if !professor.specialty.trimmedForDisplay.isEmpty {
                    Text(professor.specialty)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else if !professor.email.trimmedForDisplay.isEmpty {
                    Text(professor.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Perfil de profesor")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var initials: String {
        let words = professor.name.split(separator: " ")
        let letters = words.prefix(2).compactMap(\.first)
        return String(letters).uppercased()
    }
}

struct ProfessorDetailView: View {
    let professor: ProfessorProfile

    @EnvironmentObject var professorStore: ProfessorStore
    @EnvironmentObject var classStore: ClassStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var examStore: ExamStore
    @Environment(\.dismiss) var dismiss
    @State private var showingEditForm = false
    @State private var showingDeleteAlert = false

    private var currentProfessor: ProfessorProfile {
        professorStore.findProfessor(by: professor.id) ?? professor
    }

    private var relatedClasses: [UniversityClass] {
        classStore.classes
            .filter { professorMatches($0, professor: currentProfessor) }
            .sorted {
                if $0.semester != $1.semester {
                    return $0.semester < $1.semester
                }

                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private var relatedTasks: [TaskItem] {
        let classIds = Set(relatedClasses.map(\.id))
        return taskStore.tasks
            .filter { classIds.contains($0.classId) }
            .sorted { $0.dueDate < $1.dueDate }
    }

    private var relatedExams: [Exam] {
        let classIds = Set(relatedClasses.map(\.id))
        return examStore.exams.filter { classIds.contains($0.classId) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statsGrid
                contactSection
                notesSection
                classesSection
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 96)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Profesor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditForm = true
                    } label: {
                        Label("Editar", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            ProfessorFormView(professor: currentProfessor)
        }
        .alert("¿Eliminar profesor?", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                professorStore.deleteProfessor(currentProfessor)
                dismiss()
            }
        } message: {
            Text("Las clases conservarán el nombre escrito del profesor, pero ya no estarán vinculadas a este perfil.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 86, height: 86)
                .overlay(
                    Text(initials(for: currentProfessor.name))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(currentProfessor.name)
                    .font(.largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true)

                if !currentProfessor.specialty.trimmedForDisplay.isEmpty {
                    Text(currentProfessor.specialty)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ProfessorStatCard(
                title: "Clases",
                value: "\(relatedClasses.count)",
                subtitle: "te ha dado",
                icon: "book.closed.fill",
                color: .blue
            )

            ProfessorStatCard(
                title: "Entregas",
                value: "\(relatedTasks.count)",
                subtitle: "tareas registradas",
                icon: "checklist",
                color: .green
            )

            ProfessorStatCard(
                title: "Día favorito",
                value: favoriteDeliveryDay.value,
                subtitle: favoriteDeliveryDay.subtitle,
                icon: "calendar.badge.clock",
                color: .orange
            )

            ProfessorStatCard(
                title: "Entre tareas",
                value: averageTaskGap.value,
                subtitle: averageTaskGap.subtitle,
                icon: "clock.arrow.circlepath",
                color: .purple
            )

            ProfessorStatCard(
                title: "Exámenes",
                value: "\(relatedExams.count)",
                subtitle: "registrados",
                icon: "doc.text.fill",
                color: .teal
            )
        }
    }

    @ViewBuilder
    private var contactSection: some View {
        let contactRows = contactInfoRows

        if !contactRows.isEmpty {
            ProfessorInfoCard(title: "Contacto", icon: "person.text.rectangle", color: .blue) {
                VStack(spacing: 12) {
                    ForEach(contactRows, id: \.title) { row in
                        ProfessorInfoLine(title: row.title, value: row.value, icon: row.icon, link: row.link)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        if !currentProfessor.notes.trimmedForDisplay.isEmpty {
            ProfessorInfoCard(title: "Notas", icon: "note.text", color: .orange) {
                Text(currentProfessor.notes)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var classesSection: some View {
        ProfessorInfoCard(title: "Clases", icon: "rectangle.stack.fill", color: .green) {
            if relatedClasses.isEmpty {
                Text("Aún no hay clases vinculadas a este profesor.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(relatedClasses) { classItem in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(classItem.color)
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(classItem.name)
                                    .font(.subheadline.weight(.semibold))

                                Text("Semestre \(classItem.semester)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var contactInfoRows: [(title: String, value: String, icon: String, link: URL?)] {
        var rows: [(String, String, String, URL?)] = []

        if !currentProfessor.email.trimmedForDisplay.isEmpty {
            rows.append(("Correo", currentProfessor.email, "envelope.fill", URL(string: "mailto:\(currentProfessor.email)")))
        }

        if !currentProfessor.phone.trimmedForDisplay.isEmpty {
            rows.append(("Teléfono", currentProfessor.phone, "phone.fill", URL(string: "tel:\(currentProfessor.phone.filter(\.isNumber))")))
        }

        if !currentProfessor.officeLocation.trimmedForDisplay.isEmpty {
            rows.append(("Oficina", currentProfessor.officeLocation, "mappin.and.ellipse", nil))
        }

        if !currentProfessor.officeHours.trimmedForDisplay.isEmpty {
            rows.append(("Horario", currentProfessor.officeHours, "clock.fill", nil))
        }

        return rows
    }

    private var favoriteDeliveryDay: (value: String, subtitle: String) {
        guard !relatedTasks.isEmpty else { return ("-", "sin tareas") }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: relatedTasks) {
            calendar.component(.weekday, from: $0.dueDate)
        }

        guard let best = grouped.max(by: { lhs, rhs in
            if lhs.value.count != rhs.value.count {
                return lhs.value.count < rhs.value.count
            }

            return lhs.key > rhs.key
        }) else {
            return ("-", "sin datos")
        }

        return (weekdayName(for: best.key), "\(best.value.count) entregas")
    }

    private var averageTaskGap: (value: String, subtitle: String) {
        let dates = relatedTasks.map(\.dueDate).sorted()
        guard dates.count >= 2 else { return ("-", "requiere 2 tareas") }

        let intervals = zip(dates, dates.dropFirst()).map { next, previous in
            previous.timeIntervalSince(next)
        }
        let averageDays = intervals.reduce(0, +) / Double(intervals.count) / 86_400

        if averageDays < 1 {
            return ("<1", "día promedio")
        }

        return (String(format: "%.1f", averageDays), "días promedio")
    }

    private func professorMatches(_ classItem: UniversityClass, professor: ProfessorProfile) -> Bool {
        if classItem.professorId == professor.id {
            return true
        }

        return normalized(classItem.professor) == normalized(professor.name)
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    private func weekdayName(for weekday: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = max(0, min(weekday - 1, symbols.count - 1))
        return symbols[index].capitalized
    }

    private func initials(for name: String) -> String {
        let words = name.split(separator: " ")
        let letters = words.prefix(2).compactMap(\.first)
        return String(letters).uppercased()
    }
}

struct ProfessorFormView: View {
    @EnvironmentObject var professorStore: ProfessorStore
    @Environment(\.dismiss) var dismiss

    let professor: ProfessorProfile?

    @State private var name: String
    @State private var specialty: String
    @State private var email: String
    @State private var phone: String
    @State private var officeLocation: String
    @State private var officeHours: String
    @State private var notes: String

    init(professor: ProfessorProfile? = nil) {
        self.professor = professor
        _name = State(initialValue: professor?.name ?? "")
        _specialty = State(initialValue: professor?.specialty ?? "")
        _email = State(initialValue: professor?.email ?? "")
        _phone = State(initialValue: professor?.phone ?? "")
        _officeLocation = State(initialValue: professor?.officeLocation ?? "")
        _officeHours = State(initialValue: professor?.officeHours ?? "")
        _notes = State(initialValue: professor?.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Información básica") {
                    TextField("Nombre", text: $name)

                    TextField("Especialidad (opcional)", text: $specialty)
                }

                Section("Contacto") {
                    TextField("Correo (opcional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Teléfono (opcional)", text: $phone)
                        .keyboardType(.phonePad)

                    TextField("Oficina o ubicación (opcional)", text: $officeLocation)

                    TextField("Horario de atención (opcional)", text: $officeHours)
                }

                Section("Notas") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }

                Section {
                    Button(action: saveProfessor) {
                        HStack {
                            Spacer()
                            Text(professor == nil ? "Crear Profesor" : "Guardar Cambios")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(name.trimmedForDisplay.isEmpty)
                }
            }
            .navigationTitle(professor == nil ? "Nuevo Profesor" : "Editar Profesor")
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

    private func saveProfessor() {
        let profile = ProfessorProfile(
            id: professor?.id ?? UUID(),
            name: name.trimmedForDisplay,
            specialty: specialty.trimmedForDisplay,
            email: email.trimmedForDisplay,
            phone: phone.trimmedForDisplay,
            officeLocation: officeLocation.trimmedForDisplay,
            officeHours: officeHours.trimmedForDisplay,
            notes: notes.trimmedForDisplay,
            createdAt: professor?.createdAt ?? Date()
        )

        if professor == nil {
            professorStore.addProfessor(profile)
        } else {
            professorStore.updateProfessor(profile)
        }

        dismiss()
    }
}

private struct ProfessorStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(Circle().fill(color.opacity(0.12)))

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct ProfessorInfoCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content

    init(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)

                Text(title)
                    .font(.title3.bold())
            }

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct ProfessorInfoLine: View {
    let title: String
    let value: String
    let icon: String
    let link: URL?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let link {
                    Link(value, destination: link)
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
        }
    }
}

private extension String {
    var trimmedForDisplay: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
