//
//  ProfessorStore.swift
//  UniversityManager
//

import Combine
import Foundation

class ProfessorStore: ObservableObject {
    @Published var professors: [ProfessorProfile] = []

    private let saveKey = "savedProfessorProfiles"

    init() {
        loadProfessors()
    }

    func addProfessor(_ professor: ProfessorProfile) {
        professors.append(professor)
        saveProfessors()
    }

    func updateProfessor(_ updatedProfessor: ProfessorProfile) {
        guard let index = professors.firstIndex(where: { $0.id == updatedProfessor.id }) else { return }
        professors[index] = updatedProfessor
        saveProfessors()
    }

    func deleteProfessor(_ professor: ProfessorProfile) {
        professors.removeAll { $0.id == professor.id }
        saveProfessors()
    }

    func findProfessor(by id: UUID) -> ProfessorProfile? {
        professors.first { $0.id == id }
    }

    func sortedProfessors() -> [ProfessorProfile] {
        professors.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func saveProfessors() {
        if let encoded = try? JSONEncoder().encode(professors) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadProfessors() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([ProfessorProfile].self, from: data) else {
            return
        }

        professors = decoded
    }
}
