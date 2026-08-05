//
//  TaskStore.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI
import Combine

class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = []
    
    private let saveKey = "savedTasks"
    private var timer: Timer?
    
    init() {
        loadTasks()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Acciones
    
    func addTask(_ task: TaskItem) {
        tasks.append(task)
        saveTasks()
        scheduleNotification(for: task)
    }
    
    func updateTask(_ updatedTask: TaskItem) {
            if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                // Actualizamos el objeto completo
                tasks[index] = updatedTask
                saveTasks()
                
                // Forzamos la reprogramación de la notificación con los nuevos datos
                if updatedTask.isCompleted {
                    cancelNotification(for: updatedTask)
                } else {
                    // Aquí el Manager tomará el nuevo 'notificationHoursBefore'
                    NotificationManager.shared.scheduleTaskNotification(for: updatedTask)
                }
            }
        }
    
    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
        cancelNotification(for: task)
    }

    func deleteTasksForClass(_ classId: UUID) {
        let classTasks = tasks.filter { $0.classId == classId }
        classTasks.forEach { cancelNotification(for: $0) }
        tasks.removeAll { $0.classId == classId }
        saveTasks()
    }
    
    func markAsCompleted(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted = true
            saveTasks()
            cancelNotification(for: tasks[index]) // Borrar alarma si ya terminó la tarea
        }
    }
    
    func clearAll() {
        tasks = []
        saveTasks()
        NotificationManager.shared.cancelAllNotifications()
    }

    func rescheduleNotifications() {
        tasks.forEach { scheduleNotification(for: $0) }
    }
    
    // MARK: - Filtros
    
    func upcomingTasks(limit: Int? = nil) -> [TaskItem] {
        let upcoming = tasks
            .filter { !$0.isCompleted && $0.dueDate > Date() }
            .sorted { $0.dueDate < $1.dueDate }
        
        if let limit = limit {
            return Array(upcoming.prefix(limit))
        }
        return upcoming
    }
    
    func tasksForClass(_ classId: UUID) -> [TaskItem] {
        tasks.filter { $0.classId == classId }
    }

    func findTask(by id: UUID) -> TaskItem? {
        tasks.first { $0.id == id }
    }
    
    // MARK: - Notificaciones (Lógica interna)
    
    private func scheduleNotification(for task: TaskItem) {
        // Usamos la función del Manager que ya calcula el tiempo previo
        NotificationManager.shared.scheduleTaskNotification(for: task)
    }
    
    private func cancelNotification(for task: TaskItem) {
        // Llamamos al manager para que elimine el ID específico de esta tarea
        NotificationManager.shared.cancelNotification(for: task)
    }
    
    // MARK: - Persistencia y Timer
    
    private func startTimer() {
        // Importante: Usar [weak self] para evitar fugas de memoria
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            SharedAppStorage.set(encoded, forKey: saveKey)
            SharedAppStorage.reloadWidgets()
        }
    }
    
    private func loadTasks() {
        guard let data = SharedAppStorage.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) else {
            return
        }
        tasks = decoded
        SharedAppStorage.set(data, forKey: saveKey)
        SharedAppStorage.reloadWidgets()
    }
}
