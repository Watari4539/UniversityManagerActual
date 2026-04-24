//
//  SettingsView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var appTheme = "light"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var showingAbout = false
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.2"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Apariencia")) {
                    Picker("Tema", selection: $appTheme) {
                        Text("Claro").tag("light")
                        Text("Oscuro").tag("dark")
                        Text("Automático").tag("auto")
                    }
                }
                
                Section(header: Text("Notificaciones")) {
                    Toggle("Activar notificaciones", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            HStack {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(.blue)
                                Text("Configurar notificaciones")
                            }
                        }
                    }
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
                        HStack {
                            Image(systemName: "info.circle")
                            Text("Acerca de Illuminico")
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                            Text("Código fuente")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Configuración")
            .sheet(isPresented: $showingAbout) {
                AboutView()
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
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        )
                    
                    // App Name
                    VStack(spacing: 8) {
                        Text("Illuminico")
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
                        Text("Desarrollado por Adrian Nieto")
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

struct NotificationSettingsView: View {
    @AppStorage("taskNotifications") private var taskNotifications = true
    @AppStorage("examNotifications") private var examNotifications = true
    @AppStorage("defaultNotificationTime") private var defaultNotificationTime = 24
    
    let notificationTimes = [1, 2, 6, 12, 24, 48]
    
    var body: some View {
        Form {
            Section(header: Text("Tipos de Notificaciones")) {
                Toggle("Notificaciones de tareas", isOn: $taskNotifications)
                Toggle("Notificaciones de exámenes", isOn: $examNotifications)
            }
            
            Section(header: Text("Tiempo por Defecto")) {
                Picker("Notificar antes", selection: $defaultNotificationTime) {
                    ForEach(notificationTimes, id: \.self) { hours in
                        Text("\(hours) horas").tag(hours)
                    }
                }
            }
            
            Section(header: Text("Prueba")) {
                Button("Probar notificación") {
                    // Enviar notificación de prueba
                }
            }
            
            Section(footer: Text("Las notificaciones se enviarán a la hora configurada antes de cada vencimiento.")) {
                // Footer text
            }
        }
        .navigationTitle("Notificaciones")
        .navigationBarTitleDisplayMode(.inline)
    }
}
