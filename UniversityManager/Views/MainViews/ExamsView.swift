//
//  ExamsView.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI
import UIKit

struct ExamsView: View {
    @EnvironmentObject var examStore: ExamStore
    @EnvironmentObject var classStore: ClassStore
    @State private var showingExamDetail: Exam?
    @State private var showingEditExam: Exam?
    
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
                            
                            Text("\(examStore.upcomingExams().count) exámenes pendientes")
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
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button {
                                                hapticSuccess()
                                                withAnimation(.spring()) {
                                                    examStore.markAsCompleted(exam)
                                                }
                                            } label: {
                                                Label("Completar", systemImage: "checkmark.circle.fill")
                                            }
                                            .tint(.green)

                                            Button(role: .destructive) {
                                                withAnimation {
                                                    examStore.deleteExam(exam)
                                                }
                                            } label: {
                                                Label("Eliminar", systemImage: "trash.fill")
                                            }
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                showingExamDetail = exam
                                            } label: {
                                                Label("Detalles", systemImage: "info.circle")
                                            }
                                            .tint(.blue)

                                            Button {
                                                showingEditExam = exam
                                            } label: {
                                                Label("Editar", systemImage: "pencil")
                                            }
                                            .tint(.orange)
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
            .sheet(item: $showingEditExam) { exam in
                ExamFormView(classId: exam.classId, editingExam: exam)
            }
        }
    }

    private func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
