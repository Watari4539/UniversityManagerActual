//
//  DataPersistence.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import Foundation

class DataPersistence {
    static let shared = DataPersistence()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        encoder.outputFormatting = .prettyPrinted
    }
    
    
    func save<T: Encodable>(_ object: T, forKey key: String) {
        do {
            let data = try encoder.encode(object)
            defaults.set(data, forKey: key)
        } catch {
            print("Error saving \(key): \(error)")
        }
    }
    
    func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print("Error loading \(key): \(error)")
            return nil
        }
    }
        
    func exportAllData() -> Data? {
        struct ExportData: Codable {
            let classes: [UniversityClass]
            let tasks: [TaskItem]
            let exams: [Exam]
            let exportDate: Date
        }
        
        let exportData = ExportData(
            classes: [],
            tasks: [],
            exams: [],
            exportDate: Date()
        )
        
        do {
            return try encoder.encode(exportData)
        } catch {
            print("Error exporting data: \(error)")
            return nil
        }
    }
    
    func importData(from data: Data) -> Bool {
        struct ImportData: Codable {
            let classes: [UniversityClass]
            let tasks: [TaskItem]
            let exams: [Exam]
        }
        
        do {
            let importData = try decoder.decode(ImportData.self, from: data)
            
            return true
        } catch {
            print("Error importing data: \(error)")
            return false
        }
    }
    
    func clearAllData() {
        let keys = [
            "savedClasses",
            "savedTasks",
            "savedExams"
        ]
        
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        
        NotificationManager.shared.cancelAllNotifications()
    }
    
    // MARK: - Backup Management
    
    func createBackup() {
        let backup = [
            "classes": defaults.data(forKey: "savedClasses"),
            "tasks": defaults.data(forKey: "savedTasks"),
            "exams": defaults.data(forKey: "savedExams"),
            "backupDate": Date()
        ] as [String: Any]
        
        defaults.set(backup, forKey: "backup")
    }
    
    func restoreBackup() -> Bool {
        guard let backup = defaults.dictionary(forKey: "backup") else { return false }
        
        if let classesData = backup["classes"] as? Data {
            defaults.set(classesData, forKey: "savedClasses")
        }
        
        if let tasksData = backup["tasks"] as? Data {
            defaults.set(tasksData, forKey: "savedTasks")
        }
        
        if let examsData = backup["exams"] as? Data {
            defaults.set(examsData, forKey: "savedExams")
        }
        
        return true
    }
}
