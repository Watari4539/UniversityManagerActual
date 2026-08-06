//
//  ReminderDetailView.swift
//  UniversityManager
//

import SwiftUI

struct ReminderDetailView: View {
    let reminder: AcademicReminder
    @EnvironmentObject var reminderStore: ReminderStore
    @EnvironmentObject var classStore: ClassStore
    @Environment(\.dismiss) var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false

    private var classItem: UniversityClass? {
        reminder.classId.flatMap { classStore.findClass(by: $0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                headerCard
                classCard
                dateCard
                descriptionCard
                additionalInfoCard
                actionButtons
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 96)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Recordatorio")
        .navigationBarTitleDisplayMode(.inline)
        .alert("¿Eliminar este recordatorio?", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                reminderStore.deleteReminder(reminder)
                dismiss()
            }
        } message: {
            Text("Esta acción no se puede deshacer.")
        }
        .sheet(isPresented: $showingEdit) {
            ReminderFormView(editingReminder: reminder)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(reminder.priority.color)
                    .frame(width: 12, height: 12)

                Text(reminder.priority.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(reminder.priority.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(reminder.priority.color.opacity(0.2)))

                Spacer()

                if reminder.isCompleted {
                    Label("Completado", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Text(reminder.title)
                .font(.title.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    @ViewBuilder
    private var classCard: some View {
        if let classItem {
            HStack {
                Circle()
                    .fill(classItem.color)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "book.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 3) {
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
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fecha del Evento")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fecha")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(reminder.eventDate.formatted(date: .long, time: .omitted))
                        .font(.body.weight(.medium))
                }

                Divider()
                    .frame(height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Hora")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(reminder.eventDate.formatted(date: .omitted, time: .shortened))
                        .font(.body.weight(.medium))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Estado")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(statusColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    @ViewBuilder
    private var descriptionCard: some View {
        if !reminder.description.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Descripción")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text(reminder.description)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private var additionalInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Información Adicional")
                .font(.headline)
                .foregroundColor(.secondary)

            if let location = reminder.location, !location.isEmpty {
                infoRow(icon: "mappin.and.ellipse", color: .orange, title: "Lugar", value: location)
            }

            infoRow(icon: "bell", color: .purple, title: "Recordatorio", value: reminderText)
            infoRow(icon: "calendar.badge.clock", color: .gray, title: "Creado", value: reminder.createdAt.formatted(date: .abbreviated, time: .omitted))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !reminder.isCompleted {
                Button {
                    reminderStore.markAsCompleted(reminder)
                    dismiss()
                } label: {
                    actionLabel("Marcar como Completado", icon: "checkmark.circle.fill")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }

            Button {
                showingEdit = true
            } label: {
                actionLabel("Editar Recordatorio", icon: "pencil")
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)

            Button {
                showingDeleteAlert = true
            } label: {
                actionLabel("Eliminar Recordatorio", icon: "trash")
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.red)
            .cornerRadius(12)
        }
    }

    private func infoRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)

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

    private var statusText: String {
        if reminder.isCompleted {
            return "Completado"
        }

        if reminder.eventDate < Date() {
            return "Pasado"
        }

        return timeRemainingString(from: reminder.eventDate)
    }

    private var statusColor: Color {
        if reminder.isCompleted { return .green }
        if reminder.eventDate < Date() { return .red }
        return reminder.timeStatus.color
    }

    private var reminderText: String {
        if let notificationDate = reminder.notificationDate {
            return notificationDate.formatted(date: .abbreviated, time: .shortened)
        }

        if let hoursBefore = reminder.notificationHoursBefore {
            return "\(hoursBefore) horas antes"
        }

        return "Sin recordatorio"
    }

    private func timeRemainingString(from date: Date) -> String {
        let totalSeconds = Int(max(0, date.timeIntervalSinceNow))

        if totalSeconds < 60 {
            return "\(totalSeconds) segundos"
        } else if totalSeconds < 3600 {
            let minutes = totalSeconds / 60
            return "\(minutes) minuto\(minutes != 1 ? "s" : "")"
        } else if totalSeconds < 86400 {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            return "\(hours)h \(minutes)m"
        } else {
            let days = totalSeconds / 86400
            let hours = (totalSeconds % 86400) / 3600
            return "\(days)d \(hours)h"
        }
    }
}
