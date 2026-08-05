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
