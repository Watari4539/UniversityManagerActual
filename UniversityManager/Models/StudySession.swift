//
//  StudySession.swift
//  UniversityManager
//

import Foundation

struct StudySession: Identifiable, Codable, Equatable {
    static let maximumDuration: TimeInterval = 50 * 60

    let id: UUID
    var classId: UUID?
    var startDate: Date
    var endDate: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        classId: UUID? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.classId = classId
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
    }

    var isActive: Bool {
        endDate == nil
    }

    func duration(until date: Date = Date()) -> TimeInterval {
        max(0, (endDate ?? date).timeIntervalSince(startDate))
    }

    func cappedEndDate(for date: Date = Date()) -> Date {
        min(date, startDate.addingTimeInterval(Self.maximumDuration))
    }
}
