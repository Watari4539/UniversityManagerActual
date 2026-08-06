//
//  StudyStore.swift
//  UniversityManager
//

import Combine
import Foundation

class StudyStore: ObservableObject {
    @Published var sessions: [StudySession] = []

    private let saveKey = "savedStudySessions"
    private var timer: Timer?

    init() {
        loadSessions()
        enforceStudyLimit()
        startTimer()
        rescheduleNotifications()
    }

    deinit {
        timer?.invalidate()
    }

    var activeSession: StudySession? {
        sessions.first { $0.isActive }
    }

    func startSession(classId: UUID?) {
        guard activeSession == nil else { return }

        let session = StudySession(classId: classId)
        sessions.append(session)
        saveSessions()
        NotificationManager.shared.scheduleStudyBreakNotification(for: session)
    }

    func stopActiveSession(endDate: Date = Date()) {
        guard let index = sessions.firstIndex(where: { $0.isActive }) else { return }

        let session = sessions[index]
        sessions[index].endDate = session.cappedEndDate(for: endDate)
        saveSessions()
        NotificationManager.shared.cancelStudyBreakNotification(for: sessions[index])
    }

    func enforceStudyLimit(now: Date = Date()) {
        guard let index = sessions.firstIndex(where: { $0.isActive }) else { return }
        let session = sessions[index]

        guard session.duration(until: now) >= StudySession.maximumDuration else { return }

        sessions[index].endDate = session.startDate.addingTimeInterval(StudySession.maximumDuration)
        saveSessions()
        NotificationManager.shared.cancelStudyBreakNotification(for: sessions[index])
    }

    func deleteSession(_ session: StudySession) {
        sessions.removeAll { $0.id == session.id }
        saveSessions()
        NotificationManager.shared.cancelStudyBreakNotification(for: session)
    }

    func rescheduleNotifications() {
        enforceStudyLimit()
        guard let activeSession else { return }
        NotificationManager.shared.scheduleStudyBreakNotification(for: activeSession)
    }

    func sessions(in range: ClosedRange<Date>) -> [StudySession] {
        sessions.filter { session in
            let endDate = session.endDate ?? Date()
            return session.startDate <= range.upperBound && endDate >= range.lowerBound
        }
    }

    func totalMinutes(in range: ClosedRange<Date>) -> Int {
        sessions(in: range).reduce(0) { total, session in
            total + minutes(for: session, in: range)
        }
    }

    func minutesByDay(in range: ClosedRange<Date>, calendar: Calendar = .current) -> [Date: Int] {
        var result: [Date: Int] = [:]

        for session in sessions(in: range) {
            let sessionEnd = session.endDate ?? Date()
            let overlapStart = max(session.startDate, range.lowerBound)
            let overlapEnd = min(sessionEnd, range.upperBound)
            guard overlapEnd > overlapStart else { continue }

            var cursor = overlapStart

            while cursor < overlapEnd {
                let dayStart = calendar.startOfDay(for: cursor)
                let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? overlapEnd
                let segmentEnd = min(nextDay, overlapEnd)
                let minutes = Int(segmentEnd.timeIntervalSince(cursor) / 60)

                result[dayStart, default: 0] += max(0, minutes)
                cursor = segmentEnd
            }
        }

        return result
    }

    func minutesByClass(in range: ClosedRange<Date>) -> [UUID: Int] {
        var result: [UUID: Int] = [:]

        for session in sessions(in: range) {
            guard let classId = session.classId else { continue }
            result[classId, default: 0] += minutes(for: session, in: range)
        }

        return result
    }

    func studyDayWithMostMinutes(in range: ClosedRange<Date>, calendar: Calendar = .current) -> (date: Date, minutes: Int)? {
        minutesByDay(in: range, calendar: calendar)
            .max { $0.value < $1.value }
            .map { (date: $0.key, minutes: $0.value) }
    }

    private func minutes(for session: StudySession, in range: ClosedRange<Date>) -> Int {
        let sessionEnd = session.endDate ?? Date()
        let overlapStart = max(session.startDate, range.lowerBound)
        let overlapEnd = min(sessionEnd, range.upperBound)
        guard overlapEnd > overlapStart else { return 0 }
        return Int(overlapEnd.timeIntervalSince(overlapStart) / 60)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.enforceStudyLimit()
                self?.objectWillChange.send()
            }
        }
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([StudySession].self, from: data) else {
            return
        }

        sessions = decoded
    }
}
