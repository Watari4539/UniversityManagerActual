//
//  ReminderStore.swift
//  UniversityManager
//

import Combine
import Foundation
import SwiftUI

class ReminderStore: ObservableObject {
    @Published var reminders: [AcademicReminder] = []

    private let saveKey = "savedAcademicReminders"
    private var timer: Timer?

    init() {
        loadReminders()
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    func addReminder(_ reminder: AcademicReminder) {
        reminders.append(reminder)
        saveReminders()
        scheduleNotification(for: reminder)
    }

    func updateReminder(_ updatedReminder: AcademicReminder) {
        guard let index = reminders.firstIndex(where: { $0.id == updatedReminder.id }) else { return }
        reminders[index] = updatedReminder
        saveReminders()

        if updatedReminder.isCompleted {
            cancelNotification(for: updatedReminder)
        } else {
            scheduleNotification(for: updatedReminder)
        }
    }

    func deleteReminder(_ reminder: AcademicReminder) {
        reminders.removeAll { $0.id == reminder.id }
        saveReminders()
        cancelNotification(for: reminder)
    }

    func markAsCompleted(_ reminder: AcademicReminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].isCompleted = true
        saveReminders()
        cancelNotification(for: reminders[index])
    }

    func remindersForClass(_ classId: UUID) -> [AcademicReminder] {
        reminders.filter { $0.classId == classId }
            .sorted { $0.eventDate < $1.eventDate }
    }

    func upcomingReminders() -> [AcademicReminder] {
        reminders
            .filter { !$0.isCompleted && $0.eventDate > Date() }
            .sorted { $0.eventDate < $1.eventDate }
    }

    func rescheduleNotifications() {
        reminders.forEach { scheduleNotification(for: $0) }
    }

    private func scheduleNotification(for reminder: AcademicReminder) {
        NotificationManager.shared.scheduleReminderNotification(for: reminder)
    }

    private func cancelNotification(for reminder: AcademicReminder) {
        NotificationManager.shared.cancelNotification(for: reminder)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }

    private func saveReminders() {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadReminders() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([AcademicReminder].self, from: data) else {
            return
        }

        reminders = decoded
    }
}
