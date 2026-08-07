//
//  SemesterStatsSnapshot.swift
//  UniversityManager
//

import Foundation

struct SemesterStatsSnapshot: Codable, Equatable {
    var semester: Int
    var capturedAt: Date
    var referenceDate: Date
    var classes: [UniversityClass]
    var tasks: [TaskItem]
    var exams: [Exam]
    var gradeAverages: [SemesterStatsGradeAverageSnapshot]
    var studySessions: [StudySession]
    var totalStudyMinutes: Int
    var studyMinutesByClass: [SemesterStatsClassStudySnapshot]
    var studyDayWithMostMinutes: SemesterStatsStudyDaySnapshot?
}

struct SemesterStatsGradeAverageSnapshot: Codable, Equatable {
    var classId: UUID
    var average: Double
}

struct SemesterStatsClassStudySnapshot: Codable, Equatable {
    var classId: UUID
    var minutes: Int
}

struct SemesterStatsStudyDaySnapshot: Codable, Equatable {
    var date: Date
    var minutes: Int
}
