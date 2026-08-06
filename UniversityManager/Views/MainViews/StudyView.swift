//
//  StudyView.swift
//  UniversityManager
//

import SwiftUI

struct StudyView: View {
    @EnvironmentObject var studyStore: StudyStore
    @EnvironmentObject var classStore: ClassStore
    @State private var selectedClassId: UUID?
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var currentClasses: [UniversityClass] {
        classStore.classes(for: classStore.currentSemester)
            .sorted { $0.name < $1.name }
    }

    private var activeSession: StudySession? {
        studyStore.activeSession
    }

    private var todayRange: ClosedRange<Date> {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)?.addingTimeInterval(-1) ?? Date()
        return start...end
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                activeCard
                todayCard
                recentSessions
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 96)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Estoy Estudiando")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { date in
            now = date
            studyStore.enforceStudyLimit(now: date)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estoy estudiando")
                .font(.largeTitle.bold())

            Text("Registra sesiones libres o asociadas a una materia para ver tu esfuerzo al final del semestre.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var activeCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill((activeSession == nil ? Color.blue : Color.green).opacity(0.12))
                    .frame(width: 150, height: 150)

                VStack(spacing: 6) {
                    Image(systemName: activeSession == nil ? "timer" : "pause.circle.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundColor(activeSession == nil ? .blue : .green)

                    Text(activeSession.map { elapsedText(for: $0) } ?? "00:00")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
            }

            if let activeSession {
                VStack(spacing: 6) {
                    Text("Sesión activa")
                        .font(.headline)

                    Text(activeSubtitle(for: activeSession))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Estoy estudiando para:")
                        .font(.subheadline.weight(.semibold))

                    Picker("Materia", selection: $selectedClassId) {
                        Text("General").tag(nil as UUID?)

                        ForEach(currentClasses) { classItem in
                            Text(classItem.name).tag(Optional(classItem.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                if activeSession == nil {
                    studyStore.startSession(classId: selectedClassId)
                } else {
                    studyStore.stopActiveSession()
                }
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: activeSession == nil ? "play.fill" : "stop.fill")
                    Text(activeSession == nil ? "Empezar a estudiar" : "Detener estudio")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
            }
            .foregroundColor(.white)
            .background(activeSession == nil ? Color.blue : Color.red)
            .cornerRadius(14)

            Text("Cada sesión se detiene automáticamente al llegar a 50 minutos.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var todayCard: some View {
        StudyInfoCard(title: "Hoy", icon: "calendar", color: .orange) {
            VStack(spacing: 12) {
                StudyStatLine(title: "Tiempo estudiado", value: formatMinutes(studyStore.totalMinutes(in: todayRange)))
                StudyStatLine(title: "Sesiones", value: "\(studyStore.sessions(in: todayRange).count)")
            }
        }
    }

    @ViewBuilder
    private var recentSessions: some View {
        let recent = studyStore.sessions
            .sorted { $0.startDate > $1.startDate }
            .prefix(8)

        if !recent.isEmpty {
            StudyInfoCard(title: "Sesiones recientes", icon: "clock.arrow.circlepath", color: .blue) {
                VStack(spacing: 12) {
                    ForEach(Array(recent)) { session in
                        StudySessionRow(session: session)
                    }
                }
            }
        }
    }

    private func activeSubtitle(for session: StudySession) -> String {
        let className = session.classId
            .flatMap { classStore.findClass(by: $0)?.name } ?? "General"
        return "\(className) - inicio \(session.startDate.formatted(date: .omitted, time: .shortened))"
    }

    private func elapsedText(for session: StudySession) -> String {
        let totalSeconds = Int(min(max(0, now.timeIntervalSince(session.startDate)), StudySession.maximumDuration))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        }

        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

private struct StudyInfoCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content

    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct StudyStatLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

private struct StudySessionRow: View {
    @EnvironmentObject var classStore: ClassStore
    let session: StudySession

    private var className: String {
        session.classId.flatMap { classStore.findClass(by: $0)?.name } ?? "General"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.isActive ? "play.circle.fill" : "checkmark.circle.fill")
                .foregroundColor(session.isActive ? .green : .blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(className)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(durationText)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
    }

    private var durationText: String {
        let minutes = Int(session.duration() / 60)

        if session.isActive {
            return "Activa"
        }

        if minutes < 60 {
            return "\(minutes) min"
        }

        return "\(minutes / 60)h \(minutes % 60)m"
    }
}
