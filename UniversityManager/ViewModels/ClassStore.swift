import SwiftUI
import Combine

class ClassStore: ObservableObject {
    @Published var classes: [UniversityClass] = []
    @Published var selectedClass: UniversityClass?
    // Dentro de tu class ClassStore: ObservableObject
    @Published var currentSemester: Int = 1
    
    private let saveKey = "savedClasses"
    
    init() {
        loadClasses()
    }
    
    func addClass(_ newClass: UniversityClass) {
        classes.append(newClass)
        saveClasses()
    }
    
    func updateClass(_ updatedClass: UniversityClass) {
        if let index = classes.firstIndex(where: { $0.id == updatedClass.id }) {
            classes[index] = updatedClass
            saveClasses()
        }
    }
    
    func deleteClass(_ classToDelete: UniversityClass) {
        classes.removeAll { $0.id == classToDelete.id }
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
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadClasses() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([UniversityClass].self, from: data) else {
            // Datos de ejemplo para pruebas - CORREGIDO: usando UUID explícitos
            //classes = sampleClasses
            return
        }
        classes = decoded
    }
    
    
}
