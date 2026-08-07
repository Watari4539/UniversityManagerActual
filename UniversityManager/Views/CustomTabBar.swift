//
//  CustomTabBar.swift
//  UniversityManager
//

import SwiftUI

struct CustomTabBar: View {
    @EnvironmentObject var navigationBarStore: NavigationBarStore
    @Binding var selectedDestination: AppNavigationDestination?
    @Binding var classesResetToken: UUID

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let selectedDestination {
                    DestinationContentView(
                        destination: selectedDestination,
                        classesResetToken: classesResetToken,
                        embedInNavigation: true
                    )
                } else {
                    OthersView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 0) {
                ForEach(navigationBarStore.bottomItems) { destination in
                    TabBarButton(
                        destination: destination,
                        selectedDestination: $selectedDestination,
                        classesResetToken: $classesResetToken
                    )
                }

                MoreTabBarButton(selectedDestination: $selectedDestination)
            }
            .frame(height: 80)
            .background(
                VisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
                    .edgesIgnoringSafeArea(.bottom)
            )
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .top
            )
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct DestinationContentView: View {
    let destination: AppNavigationDestination
    let classesResetToken: UUID
    var embedInNavigation = true

    var body: some View {
        if embedInNavigation && destination.needsNavigationWrapper {
            NavigationStack {
                content
            }
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch destination {
        case .tasks:
            TasksView()
        case .exams:
            ExamsView()
        case .classes:
            ClassesView(resetToken: classesResetToken)
        case .schedule:
            ScheduleView()
        case .grades:
            GradesView()
        case .study:
            StudyView()
        case .professors:
            ProfessorsView()
        case .semesterStats:
            SemesterStatsView()
        case .reminders:
            RemindersView()
        case .semesterCalendar:
            SemesterCalendarView()
        }
    }
}

struct TabBarButton: View {
    let destination: AppNavigationDestination
    @EnvironmentObject var classStore: ClassStore
    @Binding var selectedDestination: AppNavigationDestination?
    @Binding var classesResetToken: UUID
    @State private var showingStatsFreezeAlert = false

    private var isSelected: Bool {
        selectedDestination == destination
    }

    var body: some View {
        Button {
            selectDestination()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: destination.icon)
                    .font(.system(size: 22, weight: .medium))
                    .symbolVariant(isSelected ? .fill : .none)
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(destination.tabTitle)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? .blue : .gray)
            .padding(.top, 10)
        }
        .alert("Cerrar estadísticas del semestre", isPresented: $showingStatsFreezeAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Aceptar") {
                commitSelection()
            }
        } message: {
            Text("Una vez vistas, estas estadísticas quedarán guardadas y ya no cambiarán aunque agregues tareas, exámenes, calificaciones o sesiones de estudio. También se bloqueará la fecha final del semestre. Asegúrate de que no falte nada antes de continuar.")
        }
    }

    private func selectDestination() {
        if destination == .semesterStats && needsStatsFreezeConfirmation {
            showingStatsFreezeAlert = true
        } else {
            commitSelection()
        }
    }

    private func commitSelection() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if isSelected, destination == .classes {
                classesResetToken = UUID()
            } else {
                selectedDestination = destination
            }
        }
    }

    private var needsStatsFreezeConfirmation: Bool {
        let semester = classStore.currentSemester
        return classStore.semesterInfo(for: semester).endDate != nil
            && classStore.semesterEndHasPassed(semester)
            && classStore.statsSnapshot(for: semester) == nil
            && !classStore.hasReviewedStats(for: semester)
    }
}

struct MoreTabBarButton: View {
    @Binding var selectedDestination: AppNavigationDestination?

    private var isSelected: Bool {
        selectedDestination == nil
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDestination = nil
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 22, weight: .medium))
                    .symbolVariant(isSelected ? .fill : .none)
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text("Más")
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? .blue : .gray)
            .padding(.top, 10)
        }
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}
