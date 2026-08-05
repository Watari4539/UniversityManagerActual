//
//  SemesterStatsView.swift
//  UniversityManager
//

import SwiftUI
import UIKit

struct SemesterStatsView: View {
    @EnvironmentObject var classStore: ClassStore
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var examStore: ExamStore
    @EnvironmentObject var gradeStore: GradeStore
    @State private var isRenderingShareImage = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []

    private var semester: Int {
        classStore.currentSemester
    }

    private var semesterInfo: SemesterInfo {
        classStore.semesterInfo(for: semester)
    }

    private var stats: SemesterStats {
        SemesterStats(
            semester: semester,
            classes: classStore.classes(for: semester),
            tasks: taskStore.tasks,
            exams: examStore.exams,
            gradeStore: gradeStore
        )
    }

    var body: some View {
        Group {
            if semesterInfo.endDate == nil {
                SemesterStatsLockedView(
                    icon: "calendar.badge.exclamationmark",
                    color: .orange,
                    title: "Agrega fecha de fin",
                    message: "Agrega fecha de fin, ya que la información se entrega únicamente después."
                )
            } else if !classStore.semesterEndHasPassed(semester) {
                SemesterStatsLockedView(
                    icon: "lock.clock",
                    color: .blue,
                    title: "Disponible al final del semestre",
                    message: "Las estadísticas del Semestre \(semester) se liberarán después del \(formattedDate(semesterInfo.endDate))."
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        if classStore.hasReviewedStats(for: semester) {
                            lockedEndDateWarning
                        }

                        summaryGrid
                        taskSection
                        examSection
                        classSection
                        gradeSection
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 96)
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .onAppear {
                    classStore.markStatsReviewed(for: semester)
                }
            }
        }
        .navigationTitle("Estadísticas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canExportStats {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        exportStatsImage()
                    } label: {
                        if isRenderingShareImage {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .disabled(isRenderingShareImage)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ActivityView(activityItems: shareItems)
        }
    }

    private var canExportStats: Bool {
        semesterInfo.endDate != nil && classStore.semesterEndHasPassed(semester)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Semestre \(semester)")
                .font(.largeTitle.bold())

            Text("Resumen final del periodo")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let startDate = semesterInfo.startDate, let endDate = semesterInfo.endDate {
                Label("\(formattedDate(startDate)) - \(formattedDate(endDate))", systemImage: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            } else if let endDate = semesterInfo.endDate {
                Label("Finalizó el \(formattedDate(endDate))", systemImage: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var lockedEndDateWarning: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 4) {
                Text("Fecha de fin bloqueada")
                    .font(.headline)
                    .foregroundColor(.red)

                Text("Estas estadísticas ya fueron revisadas. La fecha de fin de este semestre ya no se podrá cambiar.")
                    .font(.caption)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.08))
        )
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SemesterStatCard(
                title: "Materias",
                value: "\(stats.classes.count)",
                subtitle: "registradas",
                icon: "person.3.fill",
                color: .blue
            )

            SemesterStatCard(
                title: "Tareas",
                value: "\(stats.tasks.count)",
                subtitle: "\(stats.completedTasks) hechas",
                icon: "checklist",
                color: .green
            )

            SemesterStatCard(
                title: "Exámenes",
                value: "\(stats.exams.count)",
                subtitle: "\(stats.totalTopics) temas",
                icon: "doc.text.fill",
                color: .purple
            )

            SemesterStatCard(
                title: "Promedio",
                value: stats.semesterAverageText,
                subtitle: "del semestre",
                icon: "chart.bar.fill",
                color: .orange
            )
        }
    }

    private var taskSection: some View {
        SemesterStatsCard(title: "Tareas", icon: "checklist", color: .green) {
            VStack(spacing: 12) {
                StatLine(title: "Total", value: "\(stats.tasks.count)")
                StatLine(title: "Pendientes", value: "\(stats.pendingTasks)")
                StatLine(title: "Completadas", value: "\(stats.completedTasks)")
                StatLine(title: "Vencidas sin completar", value: "\(stats.overdueTasks)")
                StatLine(title: "Digitales", value: "\(stats.digitalTasks)")
                StatLine(title: "Físicas", value: "\(stats.physicalTasks)")

                Divider()

                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    PriorityStatLine(
                        priority: priority,
                        count: stats.taskPriorityCounts[priority, default: 0]
                    )
                }
            }
        }
    }

    private var examSection: some View {
        SemesterStatsCard(title: "Exámenes", icon: "doc.text.fill", color: .purple) {
            VStack(spacing: 12) {
                StatLine(title: "Total", value: "\(stats.exams.count)")
                StatLine(title: "Próximos", value: "\(stats.upcomingExams)")
                StatLine(title: "Finalizados", value: "\(stats.finishedExams)")
                StatLine(title: "Temas totales", value: "\(stats.totalTopics)")
                StatLine(title: "Promedio de temas por examen", value: stats.averageTopicsText)

                Divider()

                HighlightLine(
                    title: "Examen con más temas",
                    value: stats.examWithMostTopics?.title ?? "Sin datos",
                    detail: stats.examWithMostTopics.map { "\($0.topics.count) temas" } ?? "Agrega exámenes con temas"
                )
            }
        }
    }

    private var classSection: some View {
        SemesterStatsCard(title: "Materias", icon: "book.closed.fill", color: .blue) {
            VStack(spacing: 12) {
                HighlightLine(
                    title: "Más tareas",
                    value: stats.classWithMostTasks?.classItem.name ?? "Sin datos",
                    detail: stats.classWithMostTasks.map { "\($0.taskCount) tareas" } ?? "Agrega tareas"
                )

                HighlightLine(
                    title: "Menos tareas",
                    value: stats.classWithFewestTasks?.classItem.name ?? "Sin datos",
                    detail: stats.classWithFewestTasks.map { "\($0.taskCount) tareas" } ?? "Agrega materias"
                )

                HighlightLine(
                    title: "Más exámenes",
                    value: stats.classWithMostExams?.classItem.name ?? "Sin datos",
                    detail: stats.classWithMostExams.map { "\($0.examCount) exámenes" } ?? "Agrega exámenes"
                )

                StatLine(title: "Promedio de tareas por materia", value: stats.averageTasksPerClassText)
                StatLine(title: "Promedio de exámenes por materia", value: stats.averageExamsPerClassText)
            }
        }
    }

    @ViewBuilder
    private var gradeSection: some View {
        if !stats.gradeAverages.isEmpty {
            SemesterStatsCard(title: "Calificaciones", icon: "number.circle.fill", color: .teal) {
                VStack(spacing: 12) {
                    HighlightLine(
                        title: "Mejor promedio",
                        value: stats.bestAverage?.classItem.name ?? "Sin datos",
                        detail: stats.bestAverage.map { String(format: "%.1f/100", $0.average) } ?? "Sin calificaciones"
                    )

                    HighlightLine(
                        title: "Promedio más bajo",
                        value: stats.lowestAverage?.classItem.name ?? "Sin datos",
                        detail: stats.lowestAverage.map { String(format: "%.1f/100", $0.average) } ?? "Sin calificaciones"
                    )
                }
            }
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return date.formatted(.dateTime.day().month(.wide).year())
    }

    @MainActor
    private func exportStatsImage() {
        isRenderingShareImage = true

        let renderer = ImageRenderer(
            content: SemesterStatsShareImage(
                semester: semester,
                semesterInfo: semesterInfo,
                stats: stats
            )
            .frame(width: 1080, height: 1920)
        )
        renderer.scale = 1
        renderer.isOpaque = true

        if let image = renderer.uiImage {
            shareItems = [image]
            showingShareSheet = true
        }

        isRenderingShareImage = false
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct SemesterStatsShareImage: View {
    let semester: Int
    let semesterInfo: SemesterInfo
    let stats: SemesterStats

    private let ink = Color(red: 0.06, green: 0.08, blue: 0.12)
    private let muted = Color(red: 0.43, green: 0.46, blue: 0.52)
    private let paper = Color(red: 0.96, green: 0.98, blue: 1.0)
    private let blue = Color(red: 0.0, green: 0.48, blue: 1.0)
    private let green = Color(red: 0.13, green: 0.78, blue: 0.42)
    private let orange = Color(red: 1.0, green: 0.58, blue: 0.08)
    private let purple = Color(red: 0.58, green: 0.28, blue: 0.88)

    var body: some View {
        ZStack {
            paper

            VStack(alignment: .leading, spacing: 34) {
                header
                scoreHero
                headlineStats
                taskBreakdown
                highlights

                Spacer(minLength: 0)

                footer
            }
            .padding(.horizontal, 72)
            .padding(.vertical, 76)
        }
    }

    private var header: some View {
        HStack(spacing: 18) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text("Illuminico")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(ink)
                Text("Resumen final")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(muted)
            }

            Spacer()

            Text("Sem \(semester)")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Capsule().fill(blue))
        }
    }

    private var scoreHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Mi semestre en números")
                .font(.system(size: 64, weight: .black))
                .foregroundColor(ink)
                .lineLimit(2)

            Text(dateRangeText)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(muted)
        }
        .padding(.top, 8)
    }

    private var headlineStats: some View {
        HStack(spacing: 18) {
            ShareMetricTile(title: "Materias", value: "\(stats.classes.count)", color: blue)
            ShareMetricTile(title: "Tareas", value: "\(stats.tasks.count)", color: green)
            ShareMetricTile(title: "Exámenes", value: "\(stats.exams.count)", color: purple)
        }
    }

    private var taskBreakdown: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Tareas")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(ink)

            HStack(spacing: 16) {
                ShareSmallStat(title: "Hechas", value: "\(stats.completedTasks)", color: green)
                ShareSmallStat(title: "Pendientes", value: "\(stats.pendingTasks)", color: orange)
                ShareSmallStat(title: "Vencidas", value: "\(stats.overdueTasks)", color: .red)
            }

            VStack(spacing: 12) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    SharePriorityBar(
                        title: priority.rawValue,
                        count: stats.taskPriorityCounts[priority, default: 0],
                        total: max(stats.tasks.count, 1),
                        color: priority.color
                    )
                }
            }
        }
        .padding(30)
        .background(RoundedRectangle(cornerRadius: 28).fill(.white))
    }

    private var highlights: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Destacados")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(ink)

            ShareHighlightRow(
                icon: "checklist",
                title: "Materia con más tareas",
                value: stats.classWithMostTasks?.classItem.name ?? "Sin datos",
                detail: stats.classWithMostTasks.map { "\($0.taskCount) tareas" } ?? "-",
                color: green
            )

            ShareHighlightRow(
                icon: "doc.text.fill",
                title: "Examen con más temas",
                value: stats.examWithMostTopics?.title ?? "Sin datos",
                detail: stats.examWithMostTopics.map { "\($0.topics.count) temas" } ?? "-",
                color: purple
            )

            ShareHighlightRow(
                icon: "number.circle.fill",
                title: "Promedio del semestre",
                value: stats.semesterAverageText == "-" ? "Sin calificaciones" : "\(stats.semesterAverageText)/100",
                detail: stats.bestAverage.map { "Mejor: \($0.classItem.name)" } ?? "-",
                color: blue
            )

            ShareHighlightRow(
                icon: "book.closed.fill",
                title: "Menos tareas",
                value: stats.classWithFewestTasks?.classItem.name ?? "Sin datos",
                detail: stats.classWithFewestTasks.map { "\($0.taskCount) tareas" } ?? "-",
                color: orange
            )
        }
        .padding(30)
        .background(RoundedRectangle(cornerRadius: 28).fill(.white))
    }

    private var footer: some View {
        HStack {
            Text("Generado con Illuminico")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(muted)

            Spacer()

            Text(Date().formatted(.dateTime.day().month(.abbreviated).year()))
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(muted)
        }
    }

    private var dateRangeText: String {
        if let startDate = semesterInfo.startDate, let endDate = semesterInfo.endDate {
            return "\(shareDate(startDate)) - \(shareDate(endDate))"
        }

        if let endDate = semesterInfo.endDate {
            return "Finalizó el \(shareDate(endDate))"
        }

        return "Periodo finalizado"
    }

    private func shareDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).year())
    }
}

private struct ShareMetricTile: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(value)
                .font(.system(size: 58, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 0.06, green: 0.08, blue: 0.12))
        }
        .padding(26)
        .frame(maxWidth: .infinity, minHeight: 154, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 28).fill(.white))
    }
}

private struct ShareSmallStat: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(red: 0.43, green: 0.46, blue: 0.52))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 22).fill(color.opacity(0.1)))
    }
}

private struct SharePriorityBar: View {
    let title: String
    let count: Int
    let total: Int
    let color: Color

    private var progress: Double {
        min(Double(count) / Double(total), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                Spacer()
                Text("\(count)")
                    .font(.system(size: 22, weight: .bold))
            }
            .foregroundColor(Color(red: 0.06, green: 0.08, blue: 0.12))

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.14))
                    Capsule()
                        .fill(color)
                        .frame(width: max(10, geometry.size.width * progress))
                }
            }
            .frame(height: 14)
        }
    }
}

private struct ShareHighlightRow: View {
    let icon: String
    let title: String
    let value: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(color)
                .frame(width: 58, height: 58)
                .background(Circle().fill(color.opacity(0.12)))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.43, green: 0.46, blue: 0.52))
                Text(value)
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(Color(red: 0.06, green: 0.08, blue: 0.12))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 12)

            Text(detail)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }
}

private struct SemesterStats {
    let semester: Int
    let classes: [UniversityClass]
    let tasks: [TaskItem]
    let exams: [Exam]
    let gradeAverages: [ClassAverage]

    init(
        semester: Int,
        classes: [UniversityClass],
        tasks: [TaskItem],
        exams: [Exam],
        gradeStore: GradeStore
    ) {
        self.semester = semester
        self.classes = classes

        let classIds = Set(classes.map(\.id))
        self.tasks = tasks.filter { classIds.contains($0.classId) }
        self.exams = exams.filter { classIds.contains($0.classId) }
        self.gradeAverages = classes
            .map { ClassAverage(classItem: $0, average: gradeStore.averageForClass($0.id)) }
            .filter { $0.average > 0 }
    }

    var completedTasks: Int {
        tasks.filter(\.isCompleted).count
    }

    var pendingTasks: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    var overdueTasks: Int {
        tasks.filter { !$0.isCompleted && $0.dueDate < Date() }.count
    }

    var physicalTasks: Int {
        tasks.filter(\.isPhysical).count
    }

    var digitalTasks: Int {
        tasks.filter { !$0.isPhysical }.count
    }

    var upcomingExams: Int {
        exams.filter { !$0.isCompleted && $0.date > Date() }.count
    }

    var finishedExams: Int {
        exams.filter(\.isFinished).count
    }

    var totalTopics: Int {
        exams.reduce(0) { $0 + $1.topics.count }
    }

    var taskPriorityCounts: [TaskPriority: Int] {
        Dictionary(grouping: tasks, by: \.priority).mapValues(\.count)
    }

    var classTaskCounts: [ClassTaskCount] {
        classes.map { classItem in
            ClassTaskCount(
                classItem: classItem,
                taskCount: tasks.filter { $0.classId == classItem.id }.count
            )
        }
    }

    var classExamCounts: [ClassExamCount] {
        classes.map { classItem in
            ClassExamCount(
                classItem: classItem,
                examCount: exams.filter { $0.classId == classItem.id }.count
            )
        }
    }

    var classWithMostTasks: ClassTaskCount? {
        classTaskCounts.max { $0.taskCount < $1.taskCount }
    }

    var classWithFewestTasks: ClassTaskCount? {
        classTaskCounts.min { $0.taskCount < $1.taskCount }
    }

    var classWithMostExams: ClassExamCount? {
        classExamCounts.max { $0.examCount < $1.examCount }
    }

    var examWithMostTopics: Exam? {
        exams.max { $0.topics.count < $1.topics.count }
    }

    var bestAverage: ClassAverage? {
        gradeAverages.max { $0.average < $1.average }
    }

    var lowestAverage: ClassAverage? {
        gradeAverages.min { $0.average < $1.average }
    }

    var semesterAverageText: String {
        guard !gradeAverages.isEmpty else { return "-" }
        let average = gradeAverages.reduce(0) { $0 + $1.average } / Double(gradeAverages.count)
        return String(format: "%.1f", average)
    }

    var averageTopicsText: String {
        guard !exams.isEmpty else { return "-" }
        return String(format: "%.1f", Double(totalTopics) / Double(exams.count))
    }

    var averageTasksPerClassText: String {
        guard !classes.isEmpty else { return "-" }
        return String(format: "%.1f", Double(tasks.count) / Double(classes.count))
    }

    var averageExamsPerClassText: String {
        guard !classes.isEmpty else { return "-" }
        return String(format: "%.1f", Double(exams.count) / Double(classes.count))
    }
}

private struct ClassTaskCount {
    let classItem: UniversityClass
    let taskCount: Int
}

private struct ClassExamCount {
    let classItem: UniversityClass
    let examCount: Int
}

private struct ClassAverage {
    let classItem: UniversityClass
    let average: Double
}

private struct SemesterStatsLockedView: View {
    let icon: String
    let color: Color
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 54, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 96, height: 96)
                .background(Circle().fill(color.opacity(0.12)))

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

private struct SemesterStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
                .frame(width: 34, height: 34)
                .background(Circle().fill(color.opacity(0.12)))

            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 144, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct SemesterStatsCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content

    init(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)

                Text(title)
                    .font(.title3.bold())
            }

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

private struct StatLine: View {
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

private struct PriorityStatLine: View {
    let priority: TaskPriority
    let count: Int

    var body: some View {
        HStack {
            Label(priority.rawValue, systemImage: priority.icon)
                .foregroundColor(priority.color)
            Spacer()
            Text("\(count)")
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

private struct HighlightLine: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline) {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Spacer()

                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
