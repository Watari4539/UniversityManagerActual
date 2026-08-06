//
//  OthersView.swift
//  UniversityManager
//

import SwiftUI

struct OthersView: View {
    private let tabBarClearance: CGFloat = 96

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

                Section {
                    NavigationLink {
                        SettingsContentView()
                    } label: {
                        Label("Ajustes", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("Otros")
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: tabBarClearance)
            }
        }
    }
}
