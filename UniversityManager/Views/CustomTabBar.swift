//
//  CustomTabBar.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var classesResetToken: UUID
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    TasksView()
                case 1:
                    ExamsView()
                case 2:
                    ClassesView(resetToken: classesResetToken)
                case 3:
                    ScheduleView()
                case 4:
                    GradesView()
                case 5:
                    SettingsView()
                default:
                    ClassesView(resetToken: classesResetToken)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            HStack(spacing: 0) {
                ForEach(0..<6) { index in
                    TabBarButton(
                        index: index,
                        selectedTab: $selectedTab,
                        classesResetToken: $classesResetToken
                    )
                }
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

struct TabBarButton: View {
    let index: Int
    @Binding var selectedTab: Int
    @Binding var classesResetToken: UUID
    
    private var iconName: String {
        switch index {
        case 0: return "checklist"
        case 1: return "doc.text"
        case 2: return "person.3"
        case 3: return "calendar"
        case 4: return "chart.bar"
        case 5: return "gearshape"
        default: return "circle"
        }
    }
    
    private var label: String {
        switch index {
        case 0: return "Tareas"
        case 1: return "Exámenes"
        case 2: return "Clases"
        case 3: return "Horario"
        case 4: return "Notas"
        case 5: return "Ajustes"
        default: return ""
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedTab == index, index == 2 {
                    classesResetToken = UUID()
                } else {
                    selectedTab = index
                }
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .medium))
                    .symbolVariant(selectedTab == index ? .fill : .none)
                    .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                
                Text(label)
                    .font(.system(size: 10, weight: selectedTab == index ? .semibold : .regular))
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(selectedTab == index ? .blue : .gray)
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
