//
//  SemesterCalendarView.swift
//  UniversityManager
//

import SwiftUI

struct SemesterCalendarView: View {
    @EnvironmentObject var classStore: ClassStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var examStore: ExamStore
    @EnvironmentObject var studyStore: StudyStore
    @State private var selectedDate: Date?
    @State private var expandedDate: Date?
    @Namespace private var dayExpansionNamespace

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

    private var studyMinutesByDay: [Date: Int] {
        guard let dateRange else { return [:] }
        return studyStore.minutesByDay(in: dateRange, calendar: calendar)
    }

    private var totalStudyMinutes: Int {
        guard let dateRange else { return 0 }
        return studyStore.totalMinutes(in: dateRange)
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
        eventsByDay.max { lhs, rhs in
            busiestScore(for: lhs.key, events: lhs.value) < busiestScore(for: rhs.key, events: rhs.value)
        }
            .map { (date: $0.key, events: $0.value) }
    }

    private func busiestScore(for date: Date, events: [SemesterCalendarEvent]) -> SemesterDayLoadScore {
        SemesterDayLoadScore(
            eventCount: events.count,
            examCount: events.filter { $0.kind == .exam }.count,
            priorityScore: events.reduce(0) { $0 + $1.priority.loadWeight },
            studyMinutes: studyMinutesByDay[calendar.startOfDay(for: date), default: 0]
        )
    }

    private var semesterClosingRemaining: (value: String, subtitle: String) {
        guard let endDate = semesterInfo.endDate else {
            return ("-", "sin fecha de fin")
        }

        let today = calendar.startOfDay(for: Date())
        let closingDay = calendar.startOfDay(for: endDate)
        let days = calendar.dateComponents([.day], from: today, to: closingDay).day ?? 0

        if days < 0 {
            return ("Cerrado", "semestre finalizado")
        }

        if days < 7 {
            return ("\(days)", days == 1 ? "día restante" : "días restantes")
        }

        let weeks = days / 7
        let remainingDays = days % 7

        if remainingDays == 0 {
            return ("\(weeks)", weeks == 1 ? "semana restante" : "semanas restantes")
        }

        return ("\(weeks)s \(remainingDays)d", "para el cierre")
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
                ZStack {
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
                                    studyMinutesByDay: studyMinutesByDay,
                                    busiestDate: busiestDay?.date,
                                    selectedDate: $selectedDate,
                                    expandedDate: expandedDate,
                                    namespace: dayExpansionNamespace,
                                    onDayTap: handleDayTap
                                )
                            }
                        }
                        .padding()
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 96)
                    }
                    .background(Color(.systemGroupedBackground).ignoresSafeArea())

                    if let expandedDate {
                        expandedDayOverlay(for: expandedDate)
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
                title: busiestDay.map { shortDate($0.date) } ?? "-",
                value: busiestDay.map { "\($0.events.count)" } ?? "-",
                subtitle: "día más cargado",
                color: .red,
                icon: "flame.fill"
            )

            SemesterCalendarMetricCard(
                title: "Estudio",
                value: formatMinutes(totalStudyMinutes),
                subtitle: "en el semestre",
                color: .green,
                icon: "timer"
            )

            SemesterCalendarMetricCard(
                title: "Cierre",
                value: semesterClosingRemaining.value,
                subtitle: semesterClosingRemaining.subtitle,
                color: .orange,
                icon: "calendar.badge.clock"
            )
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intensidad")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    SemesterCalendarLegendItem(label: "0", count: 0)
                    SemesterCalendarLegendItem(label: "1", count: 1)
                    SemesterCalendarLegendItem(label: "2", count: 2)
                    SemesterCalendarLegendItem(label: "3", count: 3)
                    SemesterCalendarLegendItem(label: "4", count: 4)
                    SemesterCalendarLegendItem(label: "5", count: 5)
                    SemesterCalendarLegendItem(label: "6", count: 6)
                    SemesterCalendarLegendItem(label: "7", count: 7)
                    SemesterCalendarLegendItem(label: "8+", count: 8)
                }
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

    private func handleDayTap(_ date: Date) {
        let day = calendar.startOfDay(for: date)

        if selectedDate.map({ calendar.isDate($0, inSameDayAs: day) }) == true {
            withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
                expandedDate = day
            }
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                selectedDate = day
                expandedDate = nil
            }
        }
    }

    private func expandedDayOverlay(for date: Date) -> some View {
        let day = calendar.startOfDay(for: date)
        let events = eventsByDay[day] ?? []
        let studyMinutes = studyMinutesByDay[day, default: 0]

        return ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    closeExpandedDay()
                }

            SemesterCalendarDayDetailCard(
                date: day,
                events: events,
                studyMinutes: studyMinutes,
                formattedDate: formattedDate(day),
                formattedStudyMinutes: formatMinutes(studyMinutes),
                namespace: dayExpansionNamespace,
                onClose: closeExpandedDay
            )
            .padding(.horizontal, 18)
            .frame(maxWidth: 520)
            .transition(.opacity)
        }
        .zIndex(20)
    }

    private func closeExpandedDay() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
            expandedDate = nil
        }
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).year())
    }

    private func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        }

        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

private struct SemesterMonthHeatmapView: View {
    let monthStart: Date
    let dateRange: ClosedRange<Date>?
    let eventsByDay: [Date: [SemesterCalendarEvent]]
    let studyMinutesByDay: [Date: Int]
    let busiestDate: Date?
    @Binding var selectedDate: Date?
    let expandedDate: Date?
    let namespace: Namespace.ID
    let onDayTap: (Date) -> Void

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
        let studyMinutes = studyMinutesByDay[day, default: 0]
        let isInsideSemester = dateRange?.contains(day) ?? false
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        let isExpanded = expandedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        let isBusiestDay = busiestDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false

        return Button {
            guard isInsideSemester else { return }
            onDayTap(day)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isInsideSemester ? SemesterHeatmapColor.color(for: count) : Color(.systemGray5).opacity(0.45))
                    .matchedGeometryEffect(
                        id: day,
                        in: namespace,
                        properties: .frame,
                        isSource: !isExpanded
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor(isSelected: isSelected, isBusiestDay: isBusiestDay), lineWidth: isSelected ? 2.5 : (isBusiestDay ? 2.2 : 0))
                    )

                VStack(spacing: 1) {
                    Text("\(calendar.component(.day, from: day))")
                        .font(.caption.weight(.bold))

                    if studyMinutes > 0 {
                        Text(studyText(studyMinutes))
                            .font(.system(size: 8, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .foregroundColor(textColor(for: count, isInsideSemester: isInsideSemester))

                if isBusiestDay && isInsideSemester {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.yellow)
                        .shadow(color: .black.opacity(0.28), radius: 1, x: 0, y: 1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(3)
                }
            }
            .aspectRatio(1.05, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .disabled(!isInsideSemester)
        .opacity(isInsideSemester ? 1 : 0.38)
    }

    private func borderColor(isSelected: Bool, isBusiestDay: Bool) -> Color {
        if isSelected {
            return .blue
        }

        if isBusiestDay {
            return Color(red: 0.95, green: 0.68, blue: 0.16)
        }

        return .clear
    }

    private var monthTitle: String {
        monthStart.formatted(.dateTime.month(.wide).year())
    }

    private func textColor(for count: Int, isInsideSemester: Bool) -> Color {
        guard isInsideSemester else { return .secondary }
        return count >= 6 ? .white : .primary
    }

    private func studyText(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }

        return "\(minutes / 60)h"
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

private struct SemesterCalendarDayDetailCard: View {
    let date: Date
    let events: [SemesterCalendarEvent]
    let studyMinutes: Int
    let formattedDate: String
    let formattedStudyMinutes: String
    let namespace: Namespace.ID
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            studyRow
            Divider()

            ScrollView {
                if events.isEmpty {
                    Text("Sin entregas para este día.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 12) {
                        ForEach(events) { event in
                            SemesterCalendarEventRow(event: event)
                        }
                    }
                }
            }
            .frame(maxHeight: 360)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .matchedGeometryEffect(id: Calendar.current.startOfDay(for: date), in: namespace, properties: .frame)
        )
        .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 12)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Detalle del día")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Text(formattedDate)
                    .font(.title3.bold())
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            HStack(spacing: 12) {
                Text("\(events.count)")
                    .font(.title.bold())
                    .foregroundColor(SemesterHeatmapColor.color(for: events.count))

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color(.tertiarySystemGroupedBackground)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var studyRow: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundColor(.green)
                .frame(width: 28)

            Text("Estudio")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(formattedStudyMinutes)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.green)
        }
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
            return Color(red: 0.68, green: 0.82, blue: 0.25)
        case 3:
            return Color(red: 0.95, green: 0.78, blue: 0.20)
        case 4:
            return Color(red: 1.0, green: 0.62, blue: 0.16)
        case 5:
            return Color(red: 0.95, green: 0.45, blue: 0.18)
        case 6:
            return Color(red: 0.90, green: 0.25, blue: 0.14)
        case 7:
            return Color(red: 0.78, green: 0.08, blue: 0.12)
        default:
            return Color(red: 0.54, green: 0.02, blue: 0.14)
        }
    }
}

private struct SemesterDayLoadScore: Comparable {
    let eventCount: Int
    let examCount: Int
    let priorityScore: Int
    let studyMinutes: Int

    static func < (lhs: SemesterDayLoadScore, rhs: SemesterDayLoadScore) -> Bool {
        if lhs.eventCount != rhs.eventCount {
            return lhs.eventCount < rhs.eventCount
        }

        if lhs.examCount != rhs.examCount {
            return lhs.examCount < rhs.examCount
        }

        if lhs.priorityScore != rhs.priorityScore {
            return lhs.priorityScore < rhs.priorityScore
        }

        return lhs.studyMinutes < rhs.studyMinutes
    }
}

private extension TaskPriority {
    var loadWeight: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .urgent: return 4
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
