//
//  ProfessorProfile.swift
//  UniversityManager
//

import Foundation

struct ProfessorProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var specialty: String
    var email: String
    var phone: String
    var officeLocation: String
    var officeHours: String
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        specialty: String = "",
        email: String = "",
        phone: String = "",
        officeLocation: String = "",
        officeHours: String = "",
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.specialty = specialty
        self.email = email
        self.phone = phone
        self.officeLocation = officeLocation
        self.officeHours = officeHours
        self.notes = notes
        self.createdAt = createdAt
    }
}
