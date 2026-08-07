//
//  UniversityManagerWidgets.swift
//  UniversityManagerWidgets
//

import SwiftUI
import WidgetKit

private enum WidgetSharedStorage {
    static let appGroupIdentifier = "group.none.UniversityManager"
    static let savedTasksKey = "savedTasks"
    static let savedClassesKey = "savedClasses"
    static let savedExamsKey = "savedExams"
    static let savedSemesterSettingsKey = "savedSemesterSettings"
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
}

struct WidgetTaskItem: Identifiable, Codable {
    let id: UUID
    var classId: UUID
    var title: String
    var description: String
    var dueDate: Date
    var priority: WidgetTaskPriority
    var notificationHoursBefore: Int?
    var notificationDate: Date?
    var isPhysical: Bool
    var isCompleted: Bool
    var createdAt: Date
}

enum WidgetTaskPriority: String, Codable {
    case low = "Baja"
    case medium = "Media"
    case high = "Alta"
    case urgent = "Urgente"
}

struct WidgetClassItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var professor: String
    var group: String?
    var semester: Int
    var colorHex: String
    var units: Int
    var room: String
    var schedule: [WidgetScheduleSlot]
    var isExtra: Bool?
    var createdAt: Date
}

struct WidgetExamItem: Identifiable, Codable {
    let id: UUID
    var classId: UUID
    var title: String
    var topics: [String]
    var date: Date
    var room: String?
    var priority: WidgetTaskPriority
    var notificationHoursBefore: Int?
    var isCompleted: Bool
    var createdAt: Date
}

private struct WidgetSemesterSettings: Codable {
    var availableSemesters: [Int]
    var currentSemester: Int
}

struct WidgetScheduleSlot: Identifiable, Codable {
    let id: UUID
    var weekday: WidgetWeekday
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var room: String
}

enum WidgetWeekday: Int, Codable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7
}

private struct WidgetDataStore {
    static func tasks() -> [WidgetTaskItem] {
        guard let data = WidgetSharedStorage.defaults?.data(forKey: WidgetSharedStorage.savedTasksKey),
              let tasks = try? JSONDecoder().decode([WidgetTaskItem].self, from: data) else {
            return []
        }
        return tasks
    }
    
    static func classes() -> [WidgetClassItem] {
        guard let data = WidgetSharedStorage.defaults?.data(forKey: WidgetSharedStorage.savedClassesKey),
              let classes = try? JSONDecoder().decode([WidgetClassItem].self, from: data) else {
            return []
        }
        return classes
    }

    static func exams() -> [WidgetExamItem] {
        guard let data = WidgetSharedStorage.defaults?.data(forKey: WidgetSharedStorage.savedExamsKey),
              let exams = try? JSONDecoder().decode([WidgetExamItem].self, from: data) else {
            return []
        }
        return exams
    }

    static func currentSemester() -> Int {
        guard let data = WidgetSharedStorage.defaults?.data(forKey: WidgetSharedStorage.savedSemesterSettingsKey),
              let settings = try? JSONDecoder().decode(WidgetSemesterSettings.self, from: data) else {
            return 1
        }

        return settings.currentSemester
    }
}

struct UpcomingTaskEntry: TimelineEntry {
    let date: Date
    let task: WidgetTaskItem?
    let className: String?
}

struct UpcomingTaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> UpcomingTaskEntry {
        UpcomingTaskEntry(
            date: Date(),
            task: WidgetTaskItem(
                id: UUID(),
                classId: UUID(),
                title: "Proyecto final",
                description: "",
                dueDate: Date().addingTimeInterval(3600 * 20),
                priority: .high,
                notificationHoursBefore: nil,
                notificationDate: nil,
                isPhysical: false,
                isCompleted: false,
                createdAt: Date()
            ),
            className: "Diseño"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (UpcomingTaskEntry) -> Void) {
        completion(makeEntry())
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<UpcomingTaskEntry>) -> Void) {
        let now = Date()
        let upcomingTasks = WidgetDataStore.tasks()
            .filter { !$0.isCompleted && $0.dueDate > now }
            .sorted { $0.dueDate < $1.dueDate }

        var entries = [makeEntry(at: now)]

        let refreshDates = Array(Set(upcomingTasks.prefix(10).map {
            $0.dueDate.addingTimeInterval(1)
        })).sorted()

        entries.append(contentsOf: refreshDates.map { makeEntry(at: $0) })

        let nextRefresh = refreshDates.last?.addingTimeInterval(3600) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }
    
    private func makeEntry(at date: Date = Date()) -> UpcomingTaskEntry {
        let nextTask = WidgetDataStore.tasks()
            .filter { !$0.isCompleted && $0.dueDate > date }
            .sorted { $0.dueDate < $1.dueDate }
            .first
        let classes = WidgetDataStore.classes()
        let className = nextTask.flatMap { task in
            classes.first { $0.id == task.classId }?.name
        }
        
        return UpcomingTaskEntry(date: date, task: nextTask, className: className)
    }
}

struct UpcomingTaskWidgetView: View {
    let entry: UpcomingTaskEntry
    
    var body: some View {
        if let task = entry.task {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.blue)
                    Text("Próxima tarea")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                Text(task.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                let taskDescription = task.description.trimmingCharacters(in: .whitespacesAndNewlines)
                if !taskDescription.isEmpty {
                    Text(taskDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 4)
                
                HStack {
                    Label(entry.className ?? "Sin clase", systemImage: "book.closed")
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(task.dueDate, format: .dateTime.day().month().hour().minute())
                        .fontWeight(.medium)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .containerBackground(Color(.secondarySystemBackground), for: .widget)
            .widgetURL(URL(string: "illuminico://task/\(task.id.uuidString)"))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Sin tareas próximas")
                    .font(.headline)
                Text("Cuando tengas una pendiente, aparecerá aquí.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(Color(.secondarySystemBackground), for: .widget)
        }
    }
}

struct UpcomingTaskWidget: Widget {
    let kind = "UpcomingTaskWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpcomingTaskProvider()) { entry in
            UpcomingTaskWidgetView(entry: entry)
        }
        .configurationDisplayName("Próxima tarea")
        .description("Muestra la tarea pendiente que vence más pronto.")
        .supportedFamilies([.systemMedium])
    }
}

struct QuickTaskWidgetView: View {
    var body: some View {
        Link(destination: URL(string: "illuminico://quick-task")!) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48, weight: .semibold))
                Text("Nueva tarea")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .foregroundColor(.blue)
        .containerBackground(Color(.secondarySystemBackground), for: .widget)
    }
}

struct QuickTaskWidget: Widget {
    let kind = "QuickTaskWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickTaskProvider()) { _ in
            QuickTaskWidgetView()
        }
        .configurationDisplayName("Crear tarea")
        .description("Abre un formulario rápido para crear una tarea.")
        .supportedFamilies([.systemSmall])
    }
}

struct QuickTaskEntry: TimelineEntry {
    let date: Date
}

struct QuickTaskProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickTaskEntry {
        QuickTaskEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickTaskEntry) -> Void) {
        completion(QuickTaskEntry(date: Date()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickTaskEntry>) -> Void) {
        completion(Timeline(entries: [QuickTaskEntry(date: Date())], policy: .never))
    }
}

struct MonthHeatmapEntry: TimelineEntry {
    let date: Date
    let monthStart: Date
    let eventCountsByDay: [Date: Int]
}

struct MonthHeatmapProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthHeatmapEntry {
        let calendar = Self.widgetCalendar
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        var sampleCounts: [Date: Int] = [:]

        for day in [2, 6, 11, 14, 19, 25, 27] {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                sampleCounts[calendar.startOfDay(for: date)] = min(day % 8 + 1, 8)
            }
        }

        return MonthHeatmapEntry(date: now, monthStart: monthStart, eventCountsByDay: sampleCounts)
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthHeatmapEntry) -> Void) {
        completion(makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthHeatmapEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(at: now)
        let nextMidnight = Self.widgetCalendar.date(
            byAdding: .day,
            value: 1,
            to: Self.widgetCalendar.startOfDay(for: now)
        ) ?? now.addingTimeInterval(3600 * 6)

        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func makeEntry(at date: Date) -> MonthHeatmapEntry {
        let calendar = Self.widgetCalendar
        let monthStart = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let currentSemester = WidgetDataStore.currentSemester()
        let classes = WidgetDataStore.classes().filter { $0.semester == currentSemester }
        let classIds = Set(classes.map(\.id))
        let taskEvents = WidgetDataStore.tasks()
            .filter { classIds.contains($0.classId) }
            .map(\.dueDate)
        let examEvents = WidgetDataStore.exams()
            .filter { classIds.contains($0.classId) }
            .map(\.date)
        let monthInterval = calendar.dateInterval(of: .month, for: monthStart)
        var counts: [Date: Int] = [:]

        for eventDate in taskEvents + examEvents {
            guard let monthInterval, monthInterval.contains(eventDate) else { continue }
            counts[calendar.startOfDay(for: eventDate), default: 0] += 1
        }

        return MonthHeatmapEntry(date: date, monthStart: monthStart, eventCountsByDay: counts)
    }

    private static var widgetCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }
}

struct MonthHeatmapWidgetView: View {
    let entry: MonthHeatmapEntry

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private let weekdaySymbols = ["L", "M", "X", "J", "V", "S", "D"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    private var monthDays: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: entry.monthStart) else { return [] }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: entry.monthStart)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(monthTitle)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.red)
                    .lineLimit(1)

                Spacer()

                Text("Sem \(WidgetDataStore.currentSemester())")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.64))
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, height: 18)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(gridDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        monthDayCell(for: date)
                    } else {
                        Color.clear
                            .frame(width: 32, height: 32)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .containerBackground(Color(red: 0.18, green: 0.18, blue: 0.18), for: .widget)
    }

    private func monthDayCell(for date: Date) -> some View {
        let day = calendar.startOfDay(for: date)
        let count = entry.eventCountsByDay[day, default: 0]
        let isToday = calendar.isDate(day, inSameDayAs: entry.date)

        return ZStack {
            if count > 0 {
                RoundedRectangle(cornerRadius: 7)
                    .fill(WidgetHeatmapColor.color(for: count))
            }

            RoundedRectangle(cornerRadius: 7)
                .stroke(isToday ? Color.red : Color.clear, lineWidth: 2.4)

            Text("\(calendar.component(.day, from: day))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(dayTextColor(count: count, isToday: isToday))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(width: 32, height: 32)
        .frame(maxWidth: .infinity)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "LLLL"
        return formatter.string(from: entry.monthStart).uppercased()
    }

    private func dayTextColor(count: Int, isToday: Bool) -> Color {
        if count >= 6 {
            return .white
        }

        if count > 0 {
            return Color(red: 0.08, green: 0.08, blue: 0.08)
        }

        return isToday ? .red : .white.opacity(0.82)
    }
}

private enum WidgetHeatmapColor {
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

struct MonthHeatmapWidget: Widget {
    let kind = "MonthHeatmapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthHeatmapProvider()) { entry in
            MonthHeatmapWidgetView(entry: entry)
        }
        .configurationDisplayName("Calendario del mes")
        .description("Muestra el mes actual con intensidad por entregas del semestre.")
        .supportedFamilies([.systemLarge])
    }
}

@main
struct UniversityManagerWidgetsBundle: WidgetBundle {
    var body: some Widget {
        UpcomingTaskWidget()
        QuickTaskWidget()
        MonthHeatmapWidget()
    }
}
