//
//  AcademicReminder.swift
//  UniversityManager
//

import Foundation
import SwiftUI

struct AcademicReminder: Identifiable, Codable, Equatable {
    let id: UUID
    var classId: UUID?
    var title: String
    var description: String
    var eventDate: Date
    var location: String?
    var priority: TaskPriority
    var notificationHoursBefore: Int?
    var notificationDate: Date?
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        classId: UUID? = nil,
        title: String,
        description: String = "",
        eventDate: Date = Date(),
        location: String? = nil,
        priority: TaskPriority = .medium,
        notificationHoursBefore: Int? = nil,
        notificationDate: Date? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.classId = classId
        self.title = title
        self.description = description
        self.eventDate = eventDate
        self.location = location
        self.priority = priority
        self.notificationHoursBefore = notificationHoursBefore
        self.notificationDate = notificationDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    var timeStatus: TimeStatus {
        let hoursRemaining = eventDate.timeIntervalSinceNow / 3600

        if hoursRemaining <= 24 {
            return .urgent
        } else if hoursRemaining <= 72 {
            return .warning
        } else {
            return .normal
        }
    }
}
