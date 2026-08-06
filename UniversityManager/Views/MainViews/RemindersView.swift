//
//  RemindersView.swift
//  UniversityManager
//

import SwiftUI

struct RemindersView: View {
    private enum Filter: String, CaseIterable {
        case upcoming = "Próximos"
        case all = "Todos"
    }

    @EnvironmentObject var reminderStore: ReminderStore
    @EnvironmentObject var classStore: ClassStore
    @State private var showingForm = false
    @State private var filter: Filter = .upcoming

    private var filteredReminders: [AcademicReminder] {
        let source: [AcademicReminder]

        switch filter {
        case .upcoming:
            source = reminderStore.reminders.filter { !$0.isCompleted && $0.eventDate > Date() }
        case .all:
            source = reminderStore.reminders
        }

        return source.sorted {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }

            return $0.eventDate < $1.eventDate
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                Picker("Filtro", selection: $filter) {
                    ForEach(Filter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                if filteredReminders.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(filteredReminders) { reminder in
                            NavigationLink {
                                ReminderDetailView(reminder: reminder)
                            } label: {
                                ReminderCardView(reminder: reminder)
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
        .navigationTitle("Recordatorios")
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
            ReminderFormView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recordatorios")
                .font(.largeTitle.bold())

            Text("Cosas importantes que no necesariamente son tareas o exámenes.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                ReminderMetricPill(
                    title: "Próximos",
                    value: "\(reminderStore.upcomingReminders().count)",
                    color: .blue
                )

                ReminderMetricPill(
                    title: "Total",
                    value: "\(reminderStore.reminders.count)",
                    color: .purple
                )
            }
            .padding(.top, 4)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bell.badge")
                .font(.system(size: 42, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 82, height: 82)
                .background(Circle().fill(Color.blue.opacity(0.12)))

            Text(filter == .upcoming ? "Sin recordatorios próximos" : "Sin recordatorios")
                .font(.headline)

            Text("Agrega avisos generales, cambios de clase, pendientes rápidos o cualquier evento que quieras recordar.")
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

private struct ReminderMetricPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(color)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(color.opacity(0.1)))
    }
}

private struct ReminderCardView: View {
    @EnvironmentObject var classStore: ClassStore
    let reminder: AcademicReminder

    private var classItem: UniversityClass? {
        reminder.classId.flatMap { classStore.findClass(by: $0) }
    }

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(reminder.priority.color)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(reminder.title)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : reminder.kindIcon)
                        .font(.caption.weight(.bold))
                        .foregroundColor(reminder.isCompleted ? .green : reminder.priority.color)
                }

                if let classItem {
                    Label(classItem.name, systemImage: "book.closed.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Label("General", systemImage: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    CountdownView(date: reminder.eventDate)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(reminder.isCompleted ? .secondary : reminder.timeStatus.color)

                    Spacer()

                    Text(reminder.eventDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .opacity(reminder.isCompleted ? 0.62 : 1)
    }
}

private extension AcademicReminder {
    var kindIcon: String {
        notificationHoursBefore == nil && notificationDate == nil ? "bell" : "bell.fill"
    }
}
