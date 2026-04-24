//
//  DateExtensions.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import Foundation

extension Date {
    func startOfWeek(using calendar: Calendar = .current) -> Date {
        calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date!
    }
    
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
    
    func isSameDay(as otherDate: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: otherDate)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
    
    var formattedDateTime: String {
        "\(formattedDate) \(formattedTime)"
    }
    
    func timeRemainingString() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: self)
        
        if let days = components.day, days > 0 {
            if let hours = components.hour, hours > 0 {
                return "\(days)d \(hours)h"
            }
            return "\(days) día\(days != 1 ? "s" : "")"
        } else if let hours = components.hour, hours > 0 {
            if let minutes = components.minute, minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours) hora\(hours != 1 ? "s" : "")"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) minuto\(minutes != 1 ? "s" : "")"
        } else {
            return "¡Ahora!"
        }
    }
}
