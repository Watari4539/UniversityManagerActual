//
//  SettingsView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            SettingsContentView()
        }
    }
}

struct SettingsContentView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var examStore: ExamStore
    @EnvironmentObject var reminderStore: ReminderStore
    @EnvironmentObject var studyStore: StudyStore
    @AppStorage("appTheme") private var appTheme = "light"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        List {
            Section(header: Text("Notificaciones")) {
                Toggle("Activar notificaciones", isOn: $notificationsEnabled)
            }
            
            Section(header: Text("Datos")) {
                Button(role: .destructive) {
                    // Acción para exportar datos
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Exportar datos")
                    }
                }
                
                Button(role: .destructive) {
                    // Acción para borrar todos los datos
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Borrar todos los datos")
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Ajustes")
        .onAppear {
            NotificationManager.shared.setNotificationsEnabled(notificationsEnabled) { granted in
                guard granted else { return }
                taskStore.rescheduleNotifications()
                examStore.rescheduleNotifications()
                reminderStore.rescheduleNotifications()
                studyStore.rescheduleNotifications()
            }
        }
        .onChange(of: notificationsEnabled) { _, enabled in
            NotificationManager.shared.setNotificationsEnabled(enabled) { granted in
                guard granted else { return }
                taskStore.rescheduleNotifications()
                examStore.rescheduleNotifications()
                reminderStore.rescheduleNotifications()
                studyStore.rescheduleNotifications()
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon
                    Image("AppLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
                    
                    // App Name
                    VStack(spacing: 8) {
                        Text("school manager")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Tu asistente académico personal")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "calendar",
                            title: "Gestión de Horarios",
                            description: "Organiza tus clases con un horario visual"
                        )
                        
                        FeatureRow(
                            icon: "checklist",
                            title: "Seguimiento de Tareas",
                            description: "Nunca olvides una fecha de entrega"
                        )
                        
                        FeatureRow(
                            icon: "doc.text",
                            title: "Control de Exámenes",
                            description: "Prepara tus exámenes con tiempo"
                        )
                        
                        FeatureRow(
                            icon: "chart.bar",
                            title: "Registro de Calificaciones",
                            description: "Monitorea tu progreso académico"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Developer Info
                    VStack(spacing: 12) {
                        Text("Desarrollado por Illuminico")
                            .font(.headline)
                        
                        Text("Para estudiantes universitarios")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    Spacer()
                }
                .padding(.vertical, 40)
            }
            .navigationTitle("Acerca de")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("") {
                        // Dismiss
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
