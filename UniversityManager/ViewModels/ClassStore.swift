import SwiftUI
import Combine

class ClassStore: ObservableObject {
    @Published var classes: [UniversityClass] = []
    @Published var selectedClass: UniversityClass?
    @Published var currentSemester: Int = 1 {
        didSet {
            saveSemesterSettings()
        }
    }
    @Published private(set) var availableSemesters: [Int] = Array(1...9) {
        didSet {
            saveSemesterSettings()
        }
    }
    
    private let saveKey = "savedClasses"
    private let semesterSettingsKey = "savedSemesterSettings"

    var suggestedNewSemester: Int {
        var semester = 1

        while availableSemesters.contains(semester) {
            semester += 1
        }

        return semester
    }
    
    init() {
        loadSemesterSettings()
        loadClasses()
        ensureCurrentSemesterExists()
    }
    
    func addClass(_ newClass: UniversityClass) {
        classes.append(newClass)
        includeSemester(newClass.semester)
        saveClasses()
    }
    
    func updateClass(_ updatedClass: UniversityClass) {
        if let index = classes.firstIndex(where: { $0.id == updatedClass.id }) {
            classes[index] = updatedClass
            includeSemester(updatedClass.semester)
            saveClasses()
        }
    }
    
    func deleteClass(_ classToDelete: UniversityClass) {
        classes.removeAll { $0.id == classToDelete.id }
        saveClasses()
    }

    func addSemester() {
        addSemester(number: suggestedNewSemester)
    }

    func addSemester(number: Int) {
        let newSemester = max(1, number)
        guard !availableSemesters.contains(newSemester) else { return }

        availableSemesters.append(newSemester)
        availableSemesters.sort()
        currentSemester = newSemester
    }

    func setCurrentSemester(_ semester: Int) {
        guard availableSemesters.contains(semester) else { return }
        currentSemester = semester
    }

    func deleteSemester(_ semester: Int) {
        guard availableSemesters.count > 1 else { return }

        availableSemesters.removeAll { $0 == semester }
        classes.removeAll { $0.semester == semester }

        if currentSemester == semester {
            currentSemester = availableSemesters.min() ?? 1
        }

        saveClasses()
    }
    
    func classes(for semester: Int) -> [UniversityClass] {
        classes.filter { $0.semester == semester }
    }
    
    func findClass(by id: UUID) -> UniversityClass? {
        classes.first { $0.id == id }
    }
    
    private func saveClasses() {
        if let encoded = try? JSONEncoder().encode(classes) {
            SharedAppStorage.set(encoded, forKey: saveKey)
            SharedAppStorage.reloadWidgets()
        }
    }
    
    private func loadClasses() {
        guard let data = SharedAppStorage.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([UniversityClass].self, from: data) else {
            // Datos de ejemplo para pruebas - CORREGIDO: usando UUID explícitos
            //classes = sampleClasses
            return
        }
        classes = decoded
        syncAvailableSemestersWithClasses()
        SharedAppStorage.set(data, forKey: saveKey)
        SharedAppStorage.reloadWidgets()
    }

    private func saveSemesterSettings() {
        let settings = SemesterSettings(
            availableSemesters: availableSemesters,
            currentSemester: currentSemester
        )

        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: semesterSettingsKey)
        }
    }

    private func loadSemesterSettings() {
        guard let data = UserDefaults.standard.data(forKey: semesterSettingsKey),
              let settings = try? JSONDecoder().decode(SemesterSettings.self, from: data) else {
            return
        }

        let semesters = settings.availableSemesters.isEmpty ? Array(1...9) : settings.availableSemesters
        availableSemesters = Array(Set(semesters)).sorted()
        currentSemester = availableSemesters.contains(settings.currentSemester)
            ? settings.currentSemester
            : (availableSemesters.first ?? 1)
    }

    private func ensureCurrentSemesterExists() {
        guard !availableSemesters.contains(currentSemester) else { return }
        availableSemesters.append(currentSemester)
        availableSemesters.sort()
    }

    private func includeSemester(_ semester: Int) {
        guard !availableSemesters.contains(semester) else { return }
        availableSemesters.append(semester)
        availableSemesters.sort()
    }

    private func syncAvailableSemestersWithClasses() {
        let classSemesters = Set(classes.map(\.semester))
        let mergedSemesters = Set(availableSemesters).union(classSemesters)
        availableSemesters = Array(mergedSemesters).sorted()
    }
    
    
}

private struct SemesterSettings: Codable {
    var availableSemesters: [Int]
    var currentSemester: Int
}
