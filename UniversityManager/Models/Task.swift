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
    var notificationDate: Date?
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
         notificationDate: Date? = nil,
         isPhysical: Bool = false,
         isCompleted: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.classId = classId
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.priority = priority
        self.notificationHoursBefore = notificationHoursBefore
        self.notificationDate = notificationDate
        self.isPhysical = isPhysical
        self.isCompleted = isCompleted
        self.createdAt = createdAt
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

    enum CodingKeys: String, CodingKey {
        case id
        case classId
        case title
        case description
        case dueDate
        case priority
        case notificationHoursBefore
        case notificationDate
        case isPhysical
        case isCompleted
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        classId = try container.decode(UUID.self, forKey: .classId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        dueDate = try container.decode(Date.self, forKey: .dueDate)
        priority = try container.decode(TaskPriority.self, forKey: .priority)
        notificationHoursBefore = try container.decodeIfPresent(Int.self, forKey: .notificationHoursBefore)
        notificationDate = try container.decodeIfPresent(Date.self, forKey: .notificationDate)
        isPhysical = try container.decodeIfPresent(Bool.self, forKey: .isPhysical) ?? false
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(classId, forKey: .classId)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(dueDate, forKey: .dueDate)
        try container.encode(priority, forKey: .priority)
        try container.encodeIfPresent(notificationHoursBefore, forKey: .notificationHoursBefore)
        try container.encodeIfPresent(notificationDate, forKey: .notificationDate)
        try container.encode(isPhysical, forKey: .isPhysical)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(createdAt, forKey: .createdAt)
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
