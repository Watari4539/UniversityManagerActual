//
//  ExamsView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI
import UIKit

struct ExamsView: View {
    @EnvironmentObject var examStore: ExamStore
    @EnvironmentObject var classStore: ClassStore
    @State private var expandedExam: Exam?
    @State private var showingEditExam: Exam?
    @State private var examPendingDeletion: Exam?
    @Namespace private var examExpansionNamespace
    private let tabBarClearance: CGFloat = 96
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Exámenes Próximos")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("\(examStore.upcomingExams().count) exámenes pendientes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Exams List
                        if examStore.upcomingExams().isEmpty {
                            EmptyStateView(
                                icon: "doc.text",
                                title: "Sin exámenes próximos",
                                message: "No tienes exámenes programados en el futuro cercano"
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(examStore.upcomingExams()) { exam in
                                    ExamCard(exam: exam, classStore: classStore)
                                        .matchedGeometryEffect(
                                            id: exam.id,
                                            in: examExpansionNamespace,
                                            properties: .frame,
                                            isSource: expandedExam?.id != exam.id
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
                                                expandedExam = exam
                                            }
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button {
                                                hapticSuccess()
                                                withAnimation(.spring()) {
                                                    examStore.markAsCompleted(exam)
                                                }
                                            } label: {
                                                Label("Completar", systemImage: "checkmark.circle.fill")
                                            }
                                            .tint(.green)

                                            Button(role: .destructive) {
                                                examPendingDeletion = exam
                                            } label: {
                                                Label("Eliminar", systemImage: "trash.fill")
                                            }
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
                                                    expandedExam = exam
                                                }
                                            } label: {
                                                Label("Detalles", systemImage: "info.circle")
                                            }
                                            .tint(.blue)

                                            Button {
                                                showingEditExam = exam
                                            } label: {
                                                Label("Editar", systemImage: "pencil")
                                            }
                                            .tint(.orange)
                                        }
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: tabBarClearance)
                }

                if let expandedExam {
                    expandedExamOverlay(for: expandedExam)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $showingEditExam) { exam in
                ExamFormView(classId: exam.classId, editingExam: exam)
            }
            .alert(item: $examPendingDeletion) { exam in
                Alert(
                    title: Text("¿Eliminar este examen?"),
                    message: Text("Esta acción no se puede deshacer. El examen se eliminará permanentemente."),
                    primaryButton: .destructive(Text("Eliminar")) {
                        examStore.deleteExam(exam)
                        closeExpandedExam()
                        examPendingDeletion = nil
                    },
                    secondaryButton: .cancel {
                        examPendingDeletion = nil
                    }
                )
            }
        }
    }

    private func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func expandedExamOverlay(for exam: Exam) -> some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    closeExpandedExam()
                }

            UpcomingExamExpandedCard(
                exam: exam,
                namespace: examExpansionNamespace,
                onClose: closeExpandedExam,
                onEdit: {
                    closeExpandedExam()
                    showingEditExam = exam
                },
                onComplete: {
                    hapticSuccess()
                    examStore.markAsCompleted(exam)
                    closeExpandedExam()
                },
                onDelete: {
                    examPendingDeletion = exam
                }
            )
            .environmentObject(classStore)
            .padding(.horizontal, 18)
            .padding(.bottom, tabBarClearance)
            .frame(maxWidth: 520)
            .transition(.opacity)
        }
        .zIndex(20)
    }

    private func closeExpandedExam() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
            expandedExam = nil
        }
    }
}

private struct UpcomingExamExpandedCard: View {
    @EnvironmentObject var classStore: ClassStore
    let exam: Exam
    let namespace: Namespace.ID
    let onClose: () -> Void
    let onEdit: () -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void

    private var classItem: UniversityClass? {
        classStore.findClass(by: exam.classId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    classInfo
                    dateInfo
                    topicsInfo
                    additionalInfo
                    actionButtons
                }
            }
            .frame(maxHeight: 560)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .matchedGeometryEffect(id: exam.id, in: namespace, properties: .frame)
        )
        .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 12)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(exam.priority.color)
                        .frame(width: 12, height: 12)

                    Text(exam.priority.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(exam.priority.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(exam.priority.color.opacity(0.2)))
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color(.tertiarySystemGroupedBackground)))
                }
                .buttonStyle(.plain)
            }

            Text(exam.title)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var classInfo: some View {
        if let classItem {
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
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(classItem.color.opacity(0.18)))
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemGroupedBackground)))
        }
    }

    private var dateInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fecha del Examen")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 18) {
                infoColumn(title: "Fecha", value: exam.date.formatted(date: .long, time: .omitted))

                Divider()
                    .frame(height: 38)

                infoColumn(title: "Hora", value: exam.date.formatted(date: .omitted, time: .shortened))

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Estado")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    CountdownView(date: exam.date)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(exam.timeStatus.color)
                }
            }

            if let room = exam.room, !room.isEmpty {
                Divider()
                row(icon: "mappin.circle", color: .purple, title: "Salón", value: room)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemGroupedBackground)))
    }

    @ViewBuilder
    private var topicsInfo: some View {
        if !exam.topics.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Temas a Evaluar")
                    .font(.headline)
                    .foregroundColor(.secondary)

                VStack(spacing: 8) {
                    ForEach(Array(exam.topics.enumerated()), id: \.offset) { index, topic in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 6, height: 6)
                                .padding(.top, 7)

                            Text(topic)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()

                            Text("\(index + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.1)))
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemGroupedBackground)))
        }
    }

    private var additionalInfo: some View {
        VStack(spacing: 12) {
            row(icon: "bell", color: .purple, title: "Recordatorio", value: reminderText)
            row(icon: "calendar.badge.clock", color: .gray, title: "Creado", value: exam.createdAt.formatted(date: .abbreviated, time: .omitted))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemGroupedBackground)))
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: onComplete) {
                actionLabel("Marcar como Completado", icon: "checkmark.circle.fill")
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.green)
            .cornerRadius(12)

            Button(action: onEdit) {
                actionLabel("Editar Examen", icon: "pencil")
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)

            Button(action: onDelete) {
                actionLabel("Eliminar Examen", icon: "trash")
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.red)
            .cornerRadius(12)
        }
    }

    private var reminderText: String {
        if let hoursBefore = exam.notificationHoursBefore {
            return "\(hoursBefore) horas antes"
        }

        return "Sin recordatorio"
    }

    private func infoColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body.weight(.medium))
        }
    }

    private func row(icon: String, color: Color, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }

    private func actionLabel(_ title: String, icon: String) -> some View {
        HStack {
            Spacer()
            Image(systemName: icon)
            Text(title)
                .fontWeight(.semibold)
            Spacer()
        }
    }
}
