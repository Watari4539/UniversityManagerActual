//
//  Task.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI
import Foundation

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var classId: UUID
    var title: String
    var description: String
    var dueDate: Date
    var priority: TaskPriority
    var notificationHoursBefore: Int?
    var isPhysical: Bool
    var isCompleted: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(),
         classId: UUID,
         title: String,
         description: String = "",
         dueDate: Date = Date(),
         priority: TaskPriority = .medium,
         notificationHoursBefore: Int? = nil,
         isPhysical: Bool = false,
         isCompleted: Bool = false) {
        self.id = id
        self.classId = classId
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.notificationHoursBefore = notificationHoursBefore
        self.isPhysical = isPhysical
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }
    
    var timeRemaining: TimeInterval {
        dueDate.timeIntervalSinceNow
    }
    
    var timeStatus: TimeStatus {
        let hoursRemaining = timeRemaining / 3600
        
        if hoursRemaining <= 24 {
            return .urgent
        } else if hoursRemaining <= 72 {
            return .warning
        } else {
            return .normal
        }
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Baja"
    case medium = "Media"
    case high = "Alta"
    case urgent = "Urgente"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "equal.circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.circle"
        }
    }
}

enum TimeStatus {
    case normal
    case warning
    case urgent
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .orange
        case .urgent: return .red
        }
    }
}
