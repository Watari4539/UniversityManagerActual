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
    var isCompleted: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(),
         classId: UUID,
         title: String,
         topics: [String] = [],
         date: Date = Date(),
         room: String? = nil,
         priority: TaskPriority = .medium,
         notificationHoursBefore: Int? = nil,
         isCompleted: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.classId = classId
        self.title = title
        self.topics = topics
        self.date = date
        self.room = room
        self.priority = priority
        self.notificationHoursBefore = notificationHoursBefore
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
    
    var timeRemaining: TimeInterval {
        date.timeIntervalSinceNow
    }

    var isFinished: Bool {
        isCompleted || date <= Date()
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
        case topics
        case date
        case room
        case priority
        case notificationHoursBefore
        case isCompleted
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        classId = try container.decode(UUID.self, forKey: .classId)
        title = try container.decode(String.self, forKey: .title)
        topics = try container.decodeIfPresent([String].self, forKey: .topics) ?? []
        date = try container.decode(Date.self, forKey: .date)
        room = try container.decodeIfPresent(String.self, forKey: .room)
        priority = try container.decode(TaskPriority.self, forKey: .priority)
        notificationHoursBefore = try container.decodeIfPresent(Int.self, forKey: .notificationHoursBefore)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(classId, forKey: .classId)
        try container.encode(title, forKey: .title)
        try container.encode(topics, forKey: .topics)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(room, forKey: .room)
        try container.encode(priority, forKey: .priority)
        try container.encodeIfPresent(notificationHoursBefore, forKey: .notificationHoursBefore)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
