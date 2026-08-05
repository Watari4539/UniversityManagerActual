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
    var semester: Int
    var colorHex: String
    var units: Int
    var room: String
    var schedule: [WidgetScheduleSlot]
    var createdAt: Date
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
        let entry = makeEntry()
        let nextRefresh = entry.task?.dueDate.addingTimeInterval(60) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
    
    private func makeEntry() -> UpcomingTaskEntry {
        let now = Date()
        let nextTask = WidgetDataStore.tasks()
            .filter { !$0.isCompleted && $0.dueDate > now }
            .sorted { $0.dueDate < $1.dueDate }
            .first
        let classes = WidgetDataStore.classes()
        let className = nextTask.flatMap { task in
            classes.first { $0.id == task.classId }?.name
        }
        
        return UpcomingTaskEntry(date: now, task: nextTask, className: className)
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

@main
struct UniversityManagerWidgetsBundle: WidgetBundle {
    var body: some Widget {
        UpcomingTaskWidget()
        QuickTaskWidget()
    }
}
