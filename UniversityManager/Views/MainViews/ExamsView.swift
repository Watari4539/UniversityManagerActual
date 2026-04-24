//
//  ExamsView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct ExamsView: View {
    @EnvironmentObject var examStore: ExamStore
    @EnvironmentObject var classStore: ClassStore
    @State private var showingExamDetail: Exam?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Exámenes Próximos")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("\(examStore.upcomingExams().count) exámenes programados")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Exams List
                        if examStore.upcomingExams().isEmpty {
                            EmptyStateView(
                                icon: "doc.text",
                                title: "Sin exámenes próximos",
                                message: "No tienes exámenes programados en el futuro cercano"
                            )
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(examStore.upcomingExams()) { exam in
                                    ExamCard(exam: exam, classStore: classStore)
                                        .onTapGesture {
                                            showingExamDetail = exam
                                        }
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $showingExamDetail) { exam in
                ExamDetailView(exam: exam)
            }
        }
    }
}

