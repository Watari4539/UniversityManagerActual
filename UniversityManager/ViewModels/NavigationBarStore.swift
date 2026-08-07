//
//  NavigationBarStore.swift
//  UniversityManager
//

import Combine
import Foundation

class NavigationBarStore: ObservableObject {
    static let bottomLimit = 5

    @Published private(set) var orderedItems: [AppNavigationDestination] = [] {
        didSet {
            saveConfiguration()
        }
    }

    private let saveKey = "savedNavigationBarItems"

    init() {
        loadConfiguration()
    }

    var bottomItems: [AppNavigationDestination] {
        Array(orderedItems.prefix(Self.bottomLimit))
    }

    var moreItems: [AppNavigationDestination] {
        Array(orderedItems.dropFirst(Self.bottomLimit))
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        var updated = orderedItems
        updated.move(fromOffsets: source, toOffset: destination)
        orderedItems = normalized(updated)
    }

    func moveItem(_ item: AppNavigationDestination, before target: AppNavigationDestination) {
        guard item != target,
              let sourceIndex = orderedItems.firstIndex(of: item),
              let targetIndex = orderedItems.firstIndex(of: target) else {
            return
        }

        var updated = orderedItems
        let moved = updated.remove(at: sourceIndex)
        let adjustedTargetIndex = updated.firstIndex(of: target) ?? targetIndex
        updated.insert(moved, at: adjustedTargetIndex)
        orderedItems = normalized(updated)
    }

    func moveItemToBottomEnd(_ item: AppNavigationDestination) {
        moveItem(item, to: max(0, Self.bottomLimit - 1))
    }

    func moveItemToMoreStart(_ item: AppNavigationDestination) {
        moveItem(item, to: Self.bottomLimit)
    }

    func resetToDefault() {
        orderedItems = defaultOrderedItems
    }

    private func moveItem(_ item: AppNavigationDestination, to index: Int) {
        guard let sourceIndex = orderedItems.firstIndex(of: item) else { return }

        var updated = orderedItems
        let moved = updated.remove(at: sourceIndex)
        let insertionIndex = min(max(index, 0), updated.count)
        updated.insert(moved, at: insertionIndex)
        orderedItems = normalized(updated)
    }

    private func saveConfiguration() {
        guard !orderedItems.isEmpty,
              let encoded = try? JSONEncoder().encode(orderedItems) else {
            return
        }

        UserDefaults.standard.set(encoded, forKey: saveKey)
    }

    private func loadConfiguration() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([AppNavigationDestination].self, from: data) {
            orderedItems = normalized(decoded)
            return
        }

        orderedItems = defaultOrderedItems
    }

    private var defaultOrderedItems: [AppNavigationDestination] {
        AppNavigationDestination.defaultBottomItems
            + AppNavigationDestination.allCases.filter { !AppNavigationDestination.defaultBottomItems.contains($0) }
    }

    private func normalized(_ items: [AppNavigationDestination]) -> [AppNavigationDestination] {
        var seen = Set<AppNavigationDestination>()
        var normalizedItems = items.filter { item in
            guard !seen.contains(item) else { return false }
            seen.insert(item)
            return true
        }

        for item in AppNavigationDestination.allCases where !normalizedItems.contains(item) {
            normalizedItems.append(item)
        }

        return normalizedItems
    }
}
