//
//  Class.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI
import Foundation

struct UniversityClass: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var professor: String
    var group: String?
    var semester: Int
    var colorHex: String
    var units: Int
    var room: String
    var schedule: [ScheduleSlot]
    var isExtra: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(),
         name: String,
         professor: String,
         group: String? = nil,
         semester: Int,
         colorHex: String = "#007AFF",
         units: Int = 1,
         room: String = "",
         schedule: [ScheduleSlot] = [],
         isExtra: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.professor = professor
        self.group = group
        self.semester = semester
        self.colorHex = colorHex
        self.units = units
        self.room = room
        self.schedule = schedule
        self.isExtra = isExtra
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case professor
        case group
        case semester
        case colorHex
        case units
        case room
        case schedule
        case isExtra
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        professor = try container.decode(String.self, forKey: .professor)
        group = try container.decodeIfPresent(String.self, forKey: .group)
        semester = try container.decode(Int.self, forKey: .semester)
        colorHex = try container.decode(String.self, forKey: .colorHex)
        units = try container.decode(Int.self, forKey: .units)
        room = try container.decode(String.self, forKey: .room)
        schedule = try container.decode([ScheduleSlot].self, forKey: .schedule)
        isExtra = try container.decodeIfPresent(Bool.self, forKey: .isExtra) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(professor, forKey: .professor)
        try container.encodeIfPresent(group, forKey: .group)
        try container.encode(semester, forKey: .semester)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encode(units, forKey: .units)
        try container.encode(room, forKey: .room)
        try container.encode(schedule, forKey: .schedule)
        try container.encode(isExtra, forKey: .isExtra)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    // Calcula el horario para un día específico
    func schedule(for day: Weekday) -> [ScheduleSlot] {
        schedule.filter { $0.weekday == day }
    }
}

struct ScheduleSlot: Identifiable, Codable, Equatable {
    let id: UUID
    var weekday: Weekday
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var room: String
    
    var startTime: String {
        String(format: "%02d:%02d", startHour, startMinute)
    }
    
    var endTime: String {
        String(format: "%02d:%02d", endHour, endMinute)
    }
    
    var duration: Int {
        (endHour * 60 + endMinute) - (startHour * 60 + startMinute)
    }
}

enum Weekday: Int, Codable, CaseIterable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7
    
    var name: String {
        switch self {
        case .monday: return "Lunes"
        case .tuesday: return "Martes"
        case .wednesday: return "Miércoles"
        case .thursday: return "Jueves"
        case .friday: return "Viernes"
        case .saturday: return "Sábado"
        case .sunday: return "Domingo"
        }
    }
    
    var shortName: String {
        switch self {
        case .monday: return "L"
        case .tuesday: return "M"
        case .wednesday: return "X"
        case .thursday: return "J"
        case .friday: return "V"
        case .saturday: return "S"
        case .sunday: return "D"
        }
    }

    static var scheduleDays: [Weekday] {
        allCases.filter { $0 != .sunday }
    }
}
