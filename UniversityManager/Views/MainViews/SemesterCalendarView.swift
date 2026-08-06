//
//  SemesterCalendarView.swift
//  UniversityManager
//

import SwiftUI

struct SemesterCalendarView: View {
    @EnvironmentObject var classStore: ClassStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var examStore: ExamStore
    @State private var selectedDate: Date?

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private var semester: Int {
        classStore.currentSemester
    }

    private var semesterInfo: SemesterInfo {
        classStore.semesterInfo(for: semester)
    }

    private var semesterEvents: [SemesterCalendarEvent] {
        let classes = classStore.classes(for: semester)
        let classIds = Set(classes.map(\.id))
        let classNames = Dictionary(uniqueKeysWithValues: classes.map { ($0.id, $0.name) })

        let taskEvents = taskStore.tasks
            .filter { classIds.contains($0.classId) }
            .map {
                SemesterCalendarEvent(
                    title: $0.title,
                    className: classNames[$0.classId] ?? "Clase",
                    date: $0.dueDate,
                    kind: .task,
                    priority: $0.priority
                )
            }

        let examEvents = examStore.exams
            .filter { classIds.contains($0.classId) }
            .map {
                SemesterCalendarEvent(
                    title: $0.title,
                    className: classNames[$0.classId] ?? "Clase",
                    date: $0.date,
                    kind: .exam,
                    priority: $0.priority
                )
            }

        return (taskEvents + examEvents).sorted { $0.date < $1.date }
    }

    private var rangeEvents: [SemesterCalendarEvent] {
        guard let dateRange else { return [] }
        return semesterEvents.filter { event in
            let day = calendar.startOfDay(for: event.date)
            return dateRange.contains(day)
        }
    }

    private var eventsByDay: [Date: [SemesterCalendarEvent]] {
        Dictionary(grouping: rangeEvents) { event in
            calendar.startOfDay(for: event.date)
        }
    }

    private var dateRange: ClosedRange<Date>? {
        guard let startDate = semesterInfo.startDate,
              let endDate = semesterInfo.endDate else {
            return nil
        }

        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        guard start <= end else { return nil }
        return start...end
    }

    private var monthStarts: [Date] {
        guard let dateRange else { return [] }

        let startMonth = calendar.dateInterval(of: .month, for: dateRange.lowerBound)?.start ?? dateRange.lowerBound
        let endMonth = calendar.dateInterval(of: .month, for: dateRange.upperBound)?.start ?? dateRange.upperBound
        var months: [Date] = []
        var current = startMonth

        while current <= endMonth {
            months.append(current)
            guard let next = calendar.date(byAdding: .month, value: 1, to: current) else { break }
            current = next
        }

        return months
    }

    private var busiestDay: (date: Date, events: [SemesterCalendarEvent])? {
        eventsByDay.max { $0.value.count < $1.value.count }
            .map { (date: $0.key, events: $0.value) }
    }

    var body: some View {
        Group {
            if semesterInfo.startDate == nil || semesterInfo.endDate == nil {
                SemesterCalendarStateView(
                    icon: "calendar.badge.exclamationmark",
                    color: .orange,
                    title: "Configura el semestre",
                    message: "Agrega fecha de inicio y fecha de fin para construir la vista completa del semestre."
                )
            } else if dateRange == nil {
                SemesterCalendarStateView(
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    title: "Revisa las fechas",
                    message: "La fecha de fin debe ser posterior a la fecha de inicio del semestre."
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        overviewCards
                        legend

                        ForEach(monthStarts, id: \.self) { month in
                            SemesterMonthHeatmapView(
                                monthStart: month,
                                dateRange: dateRange,
                                eventsByDay: eventsByDay,
                                selectedDate: $selectedDate
                            )
                        }

                        selectedDayCard
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .onAppear {
                    if selectedDate == nil {
                        selectedDate = busiestDay?.date
                    }
                }
            }
        }
        .navigationTitle("Vista de Semestre")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Semestre \(semester)")
                .font(.largeTitle.bold())

            Text("Calendario de intensidad")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let dateRange {
                Label("\(formattedDate(dateRange.lowerBound)) - \(formattedDate(dateRange.upperBound))", systemImage: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var overviewCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SemesterCalendarMetricCard(
                title: "Entregas",
                value: "\(rangeEvents.count)",
                subtitle: "tareas y exámenes",
                color: .blue,
                icon: "tray.full.fill"
            )

            SemesterCalendarMetricCard(
                title: "Día más cargado",
                value: busiestDay.map { "\($0.events.count)" } ?? "-",
                subtitle: busiestDay.map { shortDate($0.date) } ?? "sin entregas",
                color: .red,
                icon: "flame.fill"
            )
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intensidad")
                .font(.headline)

            HStack(spacing: 10) {
                SemesterCalendarLegendItem(label: "0", count: 0)
                SemesterCalendarLegendItem(label: "1", count: 1)
                SemesterCalendarLegendItem(label: "2", count: 2)
                SemesterCalendarLegendItem(label: "3", count: 3)
                SemesterCalendarLegendItem(label: "4+", count: 4)
            }

            Text("Entre más fuerte el color, más entregas hay ese día.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    @ViewBuilder
    private var selectedDayCard: some View {
        if let selectedDate {
            let events = eventsByDay[calendar.startOfDay(for: selectedDate)] ?? []

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Detalle del día")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(formattedDate(selectedDate))
                            .font(.title3.bold())
                    }

                    Spacer()

                    Text("\(events.count)")
                        .font(.title.bold())
                        .foregroundColor(SemesterHeatmapColor.color(for: events.count))
                }

                if events.isEmpty {
                    Text("Sin entregas para este día.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    VStack(spacing: 12) {
                        ForEach(events) { event in
                            SemesterCalendarEventRow(event: event)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).year())
    }

    private func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }
}

private struct SemesterMonthHeatmapView: View {
    let monthStart: Date
    let dateRange: ClosedRange<Date>?
    let eventsByDay: [Date: [SemesterCalendarEvent]]
    @Binding var selectedDate: Date?

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private let weekdaySymbols = ["L", "M", "X", "J", "V", "S", "D"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    private var monthDays: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    private var leadingBlankCount: Int {
        guard let firstDay = monthDays.first else { return 0 }
        let weekday = calendar.component(.weekday, from: firstDay)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private var gridDays: [Date?] {
        Array(repeating: nil, count: leadingBlankCount) + monthDays.map(Optional.some)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(monthTitle)
                .font(.title2.bold())

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(gridDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(for: date)
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func dayCell(for date: Date) -> some View {
        let day = calendar.startOfDay(for: date)
        let count = eventsByDay[day]?.count ?? 0
        let isInsideSemester = dateRange?.contains(day) ?? false
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false

        return Button {
            guard isInsideSemester else { return }
            selectedDate = day
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isInsideSemester ? SemesterHeatmapColor.color(for: count) : Color(.systemGray5).opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2.5)
                    )

                Text("\(calendar.component(.day, from: day))")
                    .font(.caption.weight(.bold))
                    .foregroundColor(textColor(for: count, isInsideSemester: isInsideSemester))
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .disabled(!isInsideSemester)
        .opacity(isInsideSemester ? 1 : 0.38)
    }

    private var monthTitle: String {
        monthStart.formatted(.dateTime.month(.wide).year())
    }

    private func textColor(for count: Int, isInsideSemester: Bool) -> Color {
        guard isInsideSemester else { return .secondary }
        return count >= 3 ? .white : .primary
    }
}

private struct SemesterCalendarMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(Circle().fill(color.opacity(0.12)))

            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))

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
        .frame(maxWidth: .infinity, minHeight: 144, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct SemesterCalendarLegendItem: View {
    let label: String
    let count: Int

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 7)
                .fill(SemesterHeatmapColor.color(for: count))
                .frame(width: 34, height: 34)

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
        }
    }
}

private struct SemesterCalendarEventRow: View {
    let event: SemesterCalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.kind.icon)
                .font(.subheadline.weight(.bold))
                .foregroundColor(event.kind.color)
                .frame(width: 32, height: 32)
                .background(Circle().fill(event.kind.color.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text(event.className)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(event.date.formatted(.dateTime.hour().minute()))
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
    }
}

private struct SemesterCalendarStateView: View {
    let icon: String
    let color: Color
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 54, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 96, height: 96)
                .background(Circle().fill(color.opacity(0.12)))

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

private enum SemesterHeatmapColor {
    static func color(for count: Int) -> Color {
        switch count {
        case 0:
            return Color(.systemGray5)
        case 1:
            return Color(red: 0.31, green: 0.78, blue: 0.42)
        case 2:
            return Color(red: 0.95, green: 0.78, blue: 0.20)
        case 3:
            return Color(red: 0.95, green: 0.45, blue: 0.18)
        default:
            return Color(red: 0.86, green: 0.12, blue: 0.16)
        }
    }
}

private struct SemesterCalendarEvent: Identifiable {
    let id = UUID()
    let title: String
    let className: String
    let date: Date
    let kind: SemesterCalendarEventKind
    let priority: TaskPriority
}

private enum SemesterCalendarEventKind {
    case task
    case exam

    var icon: String {
        switch self {
        case .task: return "checklist"
        case .exam: return "doc.text.fill"
        }
    }

    var color: Color {
        switch self {
        case .task: return .blue
        case .exam: return .purple
        }
    }
}
