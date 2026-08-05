import SwiftUI
import Combine

struct SemesterInfo: Identifiable, Codable, Equatable {
    var number: Int
    var startDate: Date?
    var endDate: Date?

    var id: Int { number }
}

private struct SemesterDateRange: Codable, Equatable {
    var startDate: Date?
    var endDate: Date?
}

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
    @Published private var semesterDateRanges: [Int: SemesterDateRange] = [:] {
        didSet {
            saveSemesterSettings()
        }
    }
    @Published private var reviewedStatsSemesters: Set<Int> = [] {
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

    var semesters: [SemesterInfo] {
        availableSemesters.map { number in
            semesterInfo(for: number)
        }
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
        semesterDateRanges.removeValue(forKey: semester)
        reviewedStatsSemesters.remove(semester)
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

    func semesterInfo(for semester: Int) -> SemesterInfo {
        SemesterInfo(
            number: semester,
            startDate: semesterDateRanges[semester]?.startDate,
            endDate: semesterDateRanges[semester]?.endDate
        )
    }

    func updateSemesterDates(_ semester: Int, startDate: Date?, endDate: Date?) {
        let storedEndDate = semesterDateRanges[semester]?.endDate
        let finalEndDate = hasReviewedStats(for: semester) ? storedEndDate : endDate

        if startDate == nil && finalEndDate == nil {
            semesterDateRanges.removeValue(forKey: semester)
        } else {
            semesterDateRanges[semester] = SemesterDateRange(
                startDate: startDate,
                endDate: finalEndDate
            )
        }
    }

    func hasReviewedStats(for semester: Int) -> Bool {
        reviewedStatsSemesters.contains(semester)
    }

    func markStatsReviewed(for semester: Int) {
        reviewedStatsSemesters.insert(semester)
    }

    func semesterEndHasPassed(_ semester: Int, now: Date = Date()) -> Bool {
        guard let endDate = semesterDateRanges[semester]?.endDate else { return false }
        let startOfNextDay = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: endDate)
        ) ?? endDate

        return now >= startOfNextDay
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
            currentSemester: currentSemester,
            semesterDateRanges: semesterDateRanges,
            reviewedStatsSemesters: Array(reviewedStatsSemesters)
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
        semesterDateRanges = settings.semesterDateRanges ?? [:]
        reviewedStatsSemesters = Set(settings.reviewedStatsSemesters ?? [])
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
    var semesterDateRanges: [Int: SemesterDateRange]?
    var reviewedStatsSemesters: [Int]?
}
