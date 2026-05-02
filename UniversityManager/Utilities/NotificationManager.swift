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
    @Published var authorized = false
    
    override private init() { // Añadimos override por el NSObject
        super.init()
        UNUserNotificationCenter.current().delegate = self // Esto permite notificaciones dentro de la app
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
            DispatchQueue.main.async {
                self.authorized = success
            }
        }
    }
    
    // ESTA FUNCIÓN ES LA QUE HACE QUE APAREZCAN DENTRO DE LA APP
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func scheduleTaskNotification(for task: TaskItem) {
        guard authorized else { return }
        cancelNotification(for: task)
        
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
        content.body = "Próxima entrega: \(task.title)"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleExamNotification(for exam: Exam) {
        guard authorized else { return }
        cancelNotification(for: exam)
        guard let hoursBefore = exam.notificationHoursBefore, !exam.isCompleted else { return }
        
        let notificationDate = exam.date.addingTimeInterval(TimeInterval(-hoursBefore * 3600))
        guard notificationDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🚨 Próximo Examen"
        content.body = "\(exam.title) comienza en \(hoursBefore) horas"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: exam.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(for task: TaskItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
    
    func cancelNotification(for exam: Exam) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [exam.id.uuidString])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
