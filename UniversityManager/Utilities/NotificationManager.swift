//
//  NotificationManager.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate { // Añadimos NSObject y Delegate
    static let shared = NotificationManager()
    static let taskNotificationTapped = Notification.Name("taskNotificationTapped")
    private static let notificationsEnabledKey = "notificationsEnabled"
    @Published var authorized = false
    @Published private(set) var pendingTaskNotificationId: UUID?
    
    override private init() { // Añadimos override por el NSObject
        super.init()
        UNUserNotificationCenter.current().delegate = self // Esto permite notificaciones dentro de la app
        if notificationsEnabled {
            requestAuthorization()
        } else {
            cancelAllNotifications()
        }
    }

    var notificationsEnabled: Bool {
        if UserDefaults.standard.object(forKey: Self.notificationsEnabledKey) == nil {
            return true
        }

        return UserDefaults.standard.bool(forKey: Self.notificationsEnabledKey)
    }
    
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        guard notificationsEnabled else {
            DispatchQueue.main.async {
                self.authorized = false
                completion?(false)
            }
            return
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
            DispatchQueue.main.async {
                self.authorized = success
                completion?(success)
            }
        }
    }

    func setNotificationsEnabled(_ enabled: Bool, completion: ((Bool) -> Void)? = nil) {
        UserDefaults.standard.set(enabled, forKey: Self.notificationsEnabledKey)

        if enabled {
            requestAuthorization(completion: completion)
        } else {
            authorized = false
            cancelAllNotifications()
            completion?(false)
        }
    }
    
    // ESTA FUNCIÓN ES LA QUE HACE QUE APAREZCAN DENTRO DE LA APP
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard notificationsEnabled else {
            completionHandler([])
            return
        }

        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let type = userInfo["type"] as? String,
           type == "task",
           let taskId = userInfo["taskId"] as? String,
           let taskUUID = UUID(uuidString: taskId) {
            DispatchQueue.main.async {
                self.pendingTaskNotificationId = taskUUID
                NotificationCenter.default.post(
                    name: Self.taskNotificationTapped,
                    object: taskId
                )
            }
        }

        completionHandler()
    }

    func consumePendingTaskNotificationId() -> UUID? {
        let taskId = pendingTaskNotificationId
        pendingTaskNotificationId = nil
        return taskId
    }
    
    func scheduleTaskNotification(for task: TaskItem) {
        cancelNotification(for: task)
        guard notificationsEnabled, authorized else { return }
        
        guard !task.isCompleted else { return }

        let notificationDate: Date
        if let customNotificationDate = task.notificationDate {
            notificationDate = customNotificationDate
        } else if let hoursBefore = task.notificationHoursBefore {
            notificationDate = task.dueDate.addingTimeInterval(TimeInterval(-hoursBefore * 3600))
        } else {
            return
        }

        guard notificationDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Recordatorio de Tarea"
        content.subtitle = "Prioridad: \(task.priority.rawValue)"
        content.body = notificationBody(for: task)
        content.sound = .default
        content.userInfo = [
            "type": "task",
            "taskId": task.id.uuidString
        ]
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func notificationBody(for task: TaskItem) -> String {
        if task.notificationDate != nil {
            return "\(task.title) vence el \(taskDueDateText(task.dueDate)) a las \(taskDueTimeText(task.dueDate)). Prioridad: \(task.priority.rawValue)."
        }

        if let hoursBefore = task.notificationHoursBefore {
            let hourText = hoursBefore == 1 ? "hora" : "horas"
            return "\(task.title) vence en \(hoursBefore) \(hourText). Prioridad: \(task.priority.rawValue)."
        }

        return "\(task.title) vence pronto. Prioridad: \(task.priority.rawValue)."
    }

    private func taskDueDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d 'de' MMMM"
        return formatter.string(from: date)
    }

    private func taskDueTimeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func scheduleExamNotification(for exam: Exam) {
        cancelNotification(for: exam)
        guard notificationsEnabled, authorized else { return }
        guard let hoursBefore = exam.notificationHoursBefore, !exam.isCompleted else { return }
        
        let notificationDate = exam.date.addingTimeInterval(TimeInterval(-hoursBefore * 3600))
        guard notificationDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Próximo Examen"
        content.body = "\(exam.title) comienza en \(hoursBefore) horas"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: exam.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleReminderNotification(for reminder: AcademicReminder) {
        cancelNotification(for: reminder)
        guard notificationsEnabled, authorized else { return }
        guard !reminder.isCompleted else { return }

        let notificationDate: Date
        if let customNotificationDate = reminder.notificationDate {
            notificationDate = customNotificationDate
        } else if let hoursBefore = reminder.notificationHoursBefore {
            notificationDate = reminder.eventDate.addingTimeInterval(TimeInterval(-hoursBefore * 3600))
        } else {
            return
        }

        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Recordatorio"
        content.subtitle = "Importancia: \(reminder.priority.rawValue)"
        content.body = notificationBody(for: reminder)
        content.sound = .default
        content.userInfo = [
            "type": "reminder",
            "reminderId": reminder.id.uuidString
        ]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: reminderNotificationIdentifier(for: reminder), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func notificationBody(for reminder: AcademicReminder) -> String {
        if reminder.notificationDate != nil {
            return "\(reminder.title) será el \(taskDueDateText(reminder.eventDate)) a las \(taskDueTimeText(reminder.eventDate)). Importancia: \(reminder.priority.rawValue)."
        }

        if let hoursBefore = reminder.notificationHoursBefore {
            let hourText = hoursBefore == 1 ? "hora" : "horas"
            return "\(reminder.title) es en \(hoursBefore) \(hourText). Importancia: \(reminder.priority.rawValue)."
        }

        return "\(reminder.title) será pronto. Importancia: \(reminder.priority.rawValue)."
    }

    func scheduleStudyBreakNotification(for session: StudySession) {
        cancelStudyBreakNotification(for: session)
        guard notificationsEnabled, authorized, session.isActive else { return }

        let notificationDate = session.startDate.addingTimeInterval(50 * 60)
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Hora de descansar"
        content.body = "Llevas 50 minutos estudiando. Toma un descanso breve para volver con mejor enfoque."
        content.sound = .default
        content.userInfo = [
            "type": "studyBreak",
            "sessionId": session.id.uuidString
        ]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: studyBreakNotificationIdentifier(for: session), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(for task: TaskItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
    
    func cancelNotification(for exam: Exam) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [exam.id.uuidString])
    }

    func cancelNotification(for reminder: AcademicReminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderNotificationIdentifier(for: reminder)])
    }

    func cancelStudyBreakNotification(for session: StudySession) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [studyBreakNotificationIdentifier(for: session)])
    }

    private func reminderNotificationIdentifier(for reminder: AcademicReminder) -> String {
        "reminder-\(reminder.id.uuidString)"
    }

    private func studyBreakNotificationIdentifier(for session: StudySession) -> String {
        "study-break-\(session.id.uuidString)"
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
