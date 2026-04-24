//
//  GradeUtils.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 13/01/26.
//

import SwiftUI

// Extensión para calcular promedios
extension Array where Element == Grade {
    func average() -> Double {
        let gradesWithScore = self.filter { $0.score > 0 }
        guard !gradesWithScore.isEmpty else { return 0 }
        
        let total = gradesWithScore.reduce(0) { $0 + $1.percentage }
        return total / Double(gradesWithScore.count)
    }
}

// Helper para formato de calificaciones
extension Grade {
    var formattedScore: String {
        if score == 0 { return "-" }
        return String(format: "%.1f", score)
    }
    
    var formattedPercentage: String {
        if score == 0 { return "-" }
        return String(format: "%.1f%%", percentage)
    }
}
