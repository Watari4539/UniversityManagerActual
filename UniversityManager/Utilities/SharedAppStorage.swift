//
//  SharedAppStorage.swift
//  UniversityManager
//

import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

enum SharedAppStorage {
    static let appGroupIdentifier = "group.none.UniversityManager"
    static let savedTasksKey = "savedTasks"
    static let savedClassesKey = "savedClasses"
    static let quickTaskRequestKey = "quickTaskRequest"
    
    private static var appGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    static func data(forKey key: String) -> Data? {
        UserDefaults.standard.data(forKey: key) ?? appGroupDefaults?.data(forKey: key)
    }
    
    static func set(_ data: Data, forKey key: String) {
        UserDefaults.standard.set(data, forKey: key)
        appGroupDefaults?.set(data, forKey: key)
    }
    
    static func consumeQuickTaskRequest() -> Bool {
        guard let defaults = appGroupDefaults else { return false }
        let request = defaults.bool(forKey: quickTaskRequestKey)
        defaults.set(false, forKey: quickTaskRequestKey)
        return request
    }
    
    static func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
