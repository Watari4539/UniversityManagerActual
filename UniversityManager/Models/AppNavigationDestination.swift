//
//  AppNavigationDestination.swift
//  UniversityManager
//

import Foundation

enum AppNavigationDestination: String, Codable, CaseIterable, Identifiable, Equatable, Hashable {
    case tasks
    case exams
    case classes
    case schedule
    case grades
    case study
    case professors
    case semesterStats
    case reminders
    case semesterCalendar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tasks: return "Tareas"
        case .exams: return "Exámenes"
        case .classes: return "Clases"
        case .schedule: return "Horario"
        case .grades: return "Notas"
        case .study: return "Sesión de Estudio"
        case .professors: return "Profesores"
        case .semesterStats: return "Estadísticas"
        case .reminders: return "Recordatorios"
        case .semesterCalendar: return "Vista de Semestre"
        }
    }

    var tabTitle: String {
        switch self {
        case .study: return "Estudio"
        case .semesterStats: return "Stats"
        case .semesterCalendar: return "Semestre"
        default: return title
        }
    }

    var icon: String {
        switch self {
        case .tasks: return "checklist"
        case .exams: return "doc.text"
        case .classes: return "person.3"
        case .schedule: return "calendar"
        case .grades: return "chart.bar"
        case .study: return "timer"
        case .professors: return "person.crop.rectangle.stack"
        case .semesterStats: return "chart.pie"
        case .reminders: return "bell.badge"
        case .semesterCalendar: return "calendar.badge.clock"
        }
    }

    var needsNavigationWrapper: Bool {
        switch self {
        case .study, .professors, .semesterStats, .reminders, .semesterCalendar:
            return true
        case .tasks, .exams, .classes, .schedule, .grades:
            return false
        }
    }

    static let defaultBottomItems: [AppNavigationDestination] = [
        .tasks,
        .exams,
        .classes,
        .schedule,
        .study
    ]
}
