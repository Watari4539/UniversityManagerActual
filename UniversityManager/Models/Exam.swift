//
//  Exam.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI
import Foundation

struct Exam: Identifiable, Codable, Equatable {
    let id: UUID
    var classId: UUID
    var title: String
    var topics: [String]
    var date: Date
    var room: String?
    var priority: TaskPriority
    var notificationHoursBefore: Int?
    var createdAt: Date
    
    init(id: UUID = UUID(),
         classId: UUID,
         title: String,
         topics: [String] = [],
         date: Date = Date(),
         room: String? = nil,
         priority: TaskPriority = .medium,
         notificationHoursBefore: Int? = nil) {
        self.id = id
        self.classId = classId
        self.title = title
        self.topics = topics
        self.date = date
        self.room = room
        self.priority = priority
        self.notificationHoursBefore = notificationHoursBefore
        self.createdAt = Date()
    }
    
    var timeRemaining: TimeInterval {
        date.timeIntervalSinceNow
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
