//
//  OthersView.swift
//  UniversityManager
//

import SwiftUI

struct OthersView: View {
    @EnvironmentObject var classStore: ClassStore
    @EnvironmentObject var navigationBarStore: NavigationBarStore
    private let tabBarClearance: CGFloat = 96
    @State private var showingAbout = false
    @State private var showingStatsFreezeAlert = false
    @State private var navigateToStats = false
    @State private var navigateToSettings = false

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

    var body: some View {
        NavigationStack {
            List {
                Section("Accesos") {
                    ForEach(navigationBarStore.moreItems) { destination in
                        if destination == .semesterStats {
                            Button {
                                openSemesterStats()
                            } label: {
                                Label(destination.title, systemImage: destination.icon)
                            }
                            .foregroundColor(.primary)
                        } else {
                            NavigationLink {
                                DestinationContentView(
                                    destination: destination,
                                    classesResetToken: UUID(),
                                    embedInNavigation: false
                                )
                            } label: {
                                Label(destination.title, systemImage: destination.icon)
                            }
                        }
                    }
                }

                Section(header: Text("Acerca de")) {
                    HStack {
                        Text("Versión")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.secondary)
                    }

                    Button {
                        showingAbout = true
                    } label: {
                        Label("Acerca de school manager", systemImage: "info.circle")
                    }

                    Link(destination: URL(string: "https://illuminico-web-production.up.railway.app/")!) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Acerca de Illuminico")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Más")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigateToSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .fontWeight(.semibold)
                    }
                    .accessibilityLabel("Ajustes")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: tabBarClearance)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .navigationDestination(isPresented: $navigateToStats) {
                SemesterStatsView()
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsContentView()
            }
            .alert("Cerrar estadísticas del semestre", isPresented: $showingStatsFreezeAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Aceptar") {
                    navigateToStats = true
                }
            } message: {
                Text("Una vez vistas, estas estadísticas quedarán guardadas y ya no cambiarán aunque agregues tareas, exámenes, calificaciones o sesiones de estudio. También se bloqueará la fecha final del semestre. Asegúrate de que no falte nada antes de continuar.")
            }
        }
    }

    private func openSemesterStats() {
        let semester = classStore.currentSemester
        let needsFreezeConfirmation = classStore.semesterInfo(for: semester).endDate != nil
            && classStore.semesterEndHasPassed(semester)
            && classStore.statsSnapshot(for: semester) == nil
            && !classStore.hasReviewedStats(for: semester)

        if needsFreezeConfirmation {
            showingStatsFreezeAlert = true
        } else {
            navigateToStats = true
        }
    }
}
