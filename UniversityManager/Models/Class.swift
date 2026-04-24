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
    var semester: Int
    var colorHex: String
    var units: Int
    var room: String
    var schedule: [ScheduleSlot]
    var createdAt: Date
    
    init(id: UUID = UUID(),
         name: String,
         professor: String,
         semester: Int,
         colorHex: String = "#007AFF",
         units: Int = 1,
         room: String = "",
         schedule: [ScheduleSlot] = []) {
        self.id = id
        self.name = name
        self.professor = professor
        self.semester = semester
        self.colorHex = colorHex
        self.units = units
        self.room = room
        self.schedule = schedule
        self.createdAt = Date()
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
}
