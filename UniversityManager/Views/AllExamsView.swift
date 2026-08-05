//
//  AllExamsView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct AllExamsView: View {
    let classItem: UniversityClass
    @EnvironmentObject var examStore: ExamStore
    @EnvironmentObject var classStore: ClassStore
    @Environment(\.dismiss) var dismiss
    @State private var showingNewExam = false
    @State private var showingExamDetail: Exam?
    @State private var showingEditExam: Exam?
    @State private var selectedFilter = 0 // 0: Próximos, 1: Pasados, 2: Todos
    
    var filteredExams: [Exam] {
        let allExams = examStore.examsForClass(classItem.id)
        let now = Date()
        
        switch selectedFilter {
        case 0: // Próximos
            return allExams
                .filter { !$0.isCompleted && $0.date > now }
                .sorted { $0.date < $1.date }
        case 1: // Pasados
            return allExams
                .filter { $0.isCompleted || $0.date <= now }
                .sorted { $0.date > $1.date } // Más recientes primero
        case 2: // Todos
            return allExams.sorted { $0.date < $1.date }
        default:
            return allExams
        }
    }
    
    var upcomingCount: Int {
        examStore.examsForClass(classItem.id)
            .filter { !$0.isCompleted && $0.date > Date() }
            .count
    }
    
    var pastCount: Int {
        examStore.examsForClass(classItem.id)
            .filter { $0.isCompleted || $0.date <= Date() }
            .count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Stats Bar
                    HStack(spacing: 20) {
                        StatBadge(
                            count: upcomingCount,
                            label: "Próximos",
                            color: .orange,
                            icon: "clock"
                        )
                        
                        StatBadge(
                            count: pastCount,
                            label: "Pasados",
                            color: .gray,
                            icon: "checkmark.circle"
                        )
                        
                        StatBadge(
                            count: filteredExams.count,
                            label: "Mostrando",
                            color: .blue,
                            icon: "doc.text"
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    
                    // Filter Picker
                    Picker("Filtro", selection: $selectedFilter) {
                        Text("Próximos").tag(0)
                        Text("Pasados").tag(1)
                        Text("Todos").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    
                    // Exams List
                    if filteredExams.isEmpty {
                        EmptyExamsView(filter: selectedFilter)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredExams) { exam in
                                    ExtendedExamCard(exam: exam) {
                                        showingExamDetail = exam
                                    }
                                        .contextMenu {
                                            Button {
                                                showingEditExam = exam
                                            } label: {
                                                Label("Editar", systemImage: "pencil")
                                            }
                                            
                                            Divider()
                                            
                                            Button(role: .destructive) {
                                                examStore.deleteExam(exam)
                                            } label: {
                                                Label("Eliminar", systemImage: "trash")
                                            }
                                        }
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 70)
                        }
                    }
                }
            }
            .navigationTitle("Exámenes de \(classItem.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "")
                            Text("")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewExam = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingNewExam) {
                ExamFormView(classId: classItem.id)
            }
            .sheet(item: $showingEditExam) { exam in
                ExamFormView(classId: classItem.id, editingExam: exam)
            }
            .sheet(item: $showingExamDetail) { exam in
                ExamDetailView(exam: exam)
            }
        }
    }
}

struct ExtendedExamCard: View {
    let exam: Exam
    var onTap: () -> Void = { }
    @EnvironmentObject var classStore: ClassStore
    @State private var isPressed = false
    
    var isPast: Bool {
        exam.isFinished
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(exam.priority.color)
                    .frame(width: 10, height: 10)
                
                Text(exam.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                // Status Badge
                if isPast {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                } else if exam.timeStatus == .urgent {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
            
            // Topics Preview
            if !exam.topics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(exam.topics.prefix(3), id: \.self) { topic in
                            Text(topic)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.2))
                                )
                                .foregroundColor(.blue)
                        }
                        
                        if exam.topics.count > 3 {
                            Text("+\(exam.topics.count - 3) más")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 14)
            }
            
            // Details Row
            HStack(spacing: 16) {
                // Date
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fecha")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(exam.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                    }
                    .foregroundColor(isPast ? .gray : exam.timeStatus.color)
                }
                
                // Time
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hora")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(exam.date.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                // Room Badge
                if let room = exam.room {
                    Text(room)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.purple.opacity(0.2))
                        )
                        .foregroundColor(.purple)
                }
            }
            .padding(.leading, 14)
            
            // Time Remaining or Status
            if !isPast {
                HStack {
                    Image(systemName: "hourglass")
                        .font(.caption2)
                    
                    CountdownView(date: exam.date)
                        .font(.caption)
                        .foregroundColor(exam.timeStatus.color)
                    
                    Spacer()
                    
                    Text("\(exam.topics.count) tema\(exam.topics.count != 1 ? "s" : "")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 14)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text("Completado")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("Hace \(relativeTime(from: exam.date))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 14)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isPast ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onTap()
            }
        }
    }
    
    private func relativeTime(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days) día\(days != 1 ? "s" : "")"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hora\(hours != 1 ? "s" : "")"
        } else {
            return "poco tiempo"
        }
    }
}

struct EmptyExamsView: View {
    let filter: Int
    
    var message: String {
        switch filter {
        case 0: return "No hay exámenes próximos"
        case 1: return "No hay exámenes pasados"
        case 2: return "No hay exámenes registrados"
        default: return "No hay exámenes"
        }
    }
    
    var icon: String {
        switch filter {
        case 0: return "clock"
        case 1: return "checkmark.circle"
        case 2: return "doc.text"
        default: return "doc.text"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text(message)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct ExamDetailView: View {
    let exam: Exam
    @EnvironmentObject var examStore: ExamStore
    @EnvironmentObject var classStore: ClassStore
    @Environment(\.dismiss) var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    
    var isPast: Bool {
        exam.isFinished
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(exam.priority.color)
                                .frame(width: 12, height: 12)
                            
                            Text(exam.priority.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(exam.priority.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(exam.priority.color.opacity(0.2))
                                )
                            
                            Spacer()
                            
                            if isPast {
                                Label("Completado", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else if exam.timeStatus == .urgent {
                                Label("Próximo", systemImage: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Text(exam.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Class Info
                    if let classItem = classStore.findClass(by: exam.classId) {
                        HStack {
                            Circle()
                                .fill(classItem.color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "book.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(classItem.name)
                                    .font(.headline)
                                Text(classItem.professor)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("Sem \(classItem.semester)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(classItem.color.opacity(0.2))
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.tertiarySystemGroupedBackground))
                        )
                        .padding(.horizontal)
                    }
                    
                    // Exam Date Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(isPast ? "Fecha del Examen" : "Fecha del Examen")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Fecha")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(exam.date.formatted(date: .long, time: .omitted))
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            
                            Divider()
                                .frame(height: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hora")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(exam.date.formatted(date: .omitted, time: .shortened))
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Estado")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if isPast {
                                    Text("Completado")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.gray)
                                } else {
                                    CountdownView(date: exam.date)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(exam.timeStatus.color)
                                }
                            }
                        }
                        
                        if let room = exam.room {
                            Divider()
                            
                            HStack {
                                Image(systemName: "mappin.circle")
                                    .foregroundColor(.purple)
                                
                                Text("Salón:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(room)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                    
                    // Topics Section
                    if !exam.topics.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Temas a Evaluar")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(exam.topics, id: \.self) { topic in
                                    HStack {
                                        Circle()
                                            .fill(.blue)
                                            .frame(width: 6, height: 6)
                                        
                                        Text(topic)
                                            .font(.caption)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal)
                    }
                    
                    // Additional Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Información Adicional")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let hoursBefore = exam.notificationHoursBefore {
                            InfoRow(
                                icon: "bell",
                                label: "Recordatorio",
                                value: "\(hoursBefore) horas antes",
                                color: .purple
                            )
                        }
                        
                        InfoRow(
                            icon: "calendar.badge.clock",
                            label: "Creado",
                            value: exam.createdAt.formatted(date: .abbreviated, time: .omitted),
                            color: .gray
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        if !exam.isFinished {
                            Button(action: {
                                examStore.markAsCompleted(exam)
                                dismiss()
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Marcar como Completado")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }

                        Button(action: { showingEdit = true }) {
                            HStack {
                                Spacer()
                                Image(systemName: "pencil")
                                Text("Editar Examen")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showingDeleteAlert = true }) {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                Text("Eliminar Examen")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .alert("¿Eliminar este examen?", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Eliminar", role: .destructive) {
                    deleteExam()
                }
            } message: {
                Text("Esta acción no se puede deshacer. El examen se eliminará permanentemente.")
            }
            .sheet(isPresented: $showingEdit) {
                ExamFormView(classId: exam.classId, editingExam: exam)
            }
        }
    }
    
    private func deleteExam() {
        examStore.deleteExam(exam)
        dismiss()
    }
}
