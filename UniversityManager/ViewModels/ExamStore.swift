//
//  ExamStore.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI
import Combine

class ExamStore: ObservableObject {
    @Published var exams: [Exam] = []
    
    private let saveKey = "savedExams"
    private var timer: Timer?
    
    init() {
        loadExams()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Acciones
    
    func addExam(_ exam: Exam) {
        exams.append(exam)
        saveExams()
        scheduleNotification(for: exam)
    }
    
    func updateExam(_ updatedExam: Exam) {
        if let index = exams.firstIndex(where: { $0.id == updatedExam.id }) {
            exams[index] = updatedExam
            saveExams()
            if updatedExam.isCompleted {
                cancelNotification(for: updatedExam)
            } else {
                scheduleNotification(for: updatedExam)
            }
        }
    }
    
    func deleteExam(_ exam: Exam) {
        exams.removeAll { $0.id == exam.id }
        saveExams()
        cancelNotification(for: exam)
    }

    func markAsCompleted(_ exam: Exam) {
        if let index = exams.firstIndex(where: { $0.id == exam.id }) {
            exams[index].isCompleted = true
            saveExams()
            cancelNotification(for: exams[index])
        }
    }
    
    func clearAll() {
        exams = []
        saveExams()
        // No borramos todas las notificaciones de la app, solo las de exámenes
        // Pero como en Settings borramos todo, el NotificationManager.shared.cancelAllNotifications()
        // que pusimos en SettingsView se encarga de todo.
    }
    
    // MARK: - Filtros
    
    func upcomingExams(limit: Int? = nil) -> [Exam] {
        let upcoming = exams
            .filter { !$0.isCompleted && $0.date > Date() }
            .sorted { $0.date < $1.date }
        
        if let limit = limit {
            return Array(upcoming.prefix(limit))
        }
        return upcoming
    }
    
    func examsForClass(_ classId: UUID) -> [Exam] {
        exams.filter { $0.classId == classId }
    }
    
    // MARK: - Notificaciones
    
    private func scheduleNotification(for exam: Exam) {
        NotificationManager.shared.scheduleExamNotification(for: exam)
    }
    
    private func cancelNotification(for exam: Exam) {
        NotificationManager.shared.cancelNotification(for: exam)
    }
    
    // MARK: - Persistencia
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
    
    private func saveExams() {
        if let encoded = try? JSONEncoder().encode(exams) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadExams() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Exam].self, from: data) else {
            return
        }
        exams = decoded
    }
}
