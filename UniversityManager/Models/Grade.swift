//
//  Grade.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import Foundation

struct Grade: Identifiable, Codable, Equatable {
    let id: UUID
    var classId: UUID
    var unit: Int
    var score: Double
    var maxScore: Double
    var dateRecorded: Date
    var notes: String?
    
    var percentage: Double {
        (score / maxScore) * 100
    }
    
    var letterGrade: String {
        switch percentage {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }
}

struct ClassGrades {
    var classId: UUID
    var grades: [Grade]
    
    var average: Double {
        guard !grades.isEmpty else { return 0 }
        let total = grades.reduce(0) { $0 + $1.percentage }
        return total / Double(grades.count)
    }
    
    var isComplete: Bool {
        // Esto debería compararse con el número de unidades de la clase
        // Se implementará en el ViewModel
        false
    }
}
