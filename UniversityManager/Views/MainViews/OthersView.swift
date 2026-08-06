//
//  OthersView.swift
//  UniversityManager
//

import SwiftUI

struct OthersView: View {
    private let tabBarClearance: CGFloat = 96
    @State private var showingAbout = false

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

    var body: some View {
        NavigationView {
            List {
                Section("Resumen") {
                    NavigationLink {
                        SemesterStatsView()
                    } label: {
                        Label("Estadísticas del Semestre", systemImage: "chart.pie.fill")
                    }
                }

                Section("Semestre") {
                    NavigationLink {
                        SemesterCalendarView()
                    } label: {
                        Label("Vista de Semestre", systemImage: "calendar")
                    }
                }

                Section("Recordatorios") {
                    NavigationLink {
                        RemindersView()
                    } label: {
                        Label("Recordatorios", systemImage: "bell.badge.fill")
                    }
                }

                Section("Estoy Estudiando") {
                    NavigationLink {
                        StudyView()
                    } label: {
                        Label("Sesión de Estudio", systemImage: "timer")
                    }
                }

                Section {
                    NavigationLink {
                        SettingsContentView()
                    } label: {
                        Label("Ajustes", systemImage: "gearshape")
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
            .navigationTitle("Otros")
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: tabBarClearance)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
}
