//
//  ExamCard.swift
//  UniversityManager
//
//  Created by Adrián Nieto on 12/01/26.
//

import SwiftUI

struct ExamCard: View {
    let exam: Exam
    let classStore: ClassStore
    
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(exam.priority.color)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(exam.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()

                    Image(systemName: exam.isFinished ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor(exam.isFinished ? .green : .gray.opacity(0.5))
                    
                    if let classItem = classStore.findClass(by: exam.classId) {
                        Circle()
                            .fill(classItem.color)
                            .frame(width: 12, height: 12)
                    }
                }
                
                if let classItem = classStore.findClass(by: exam.classId) {
                    Text(classItem.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if !exam.topics.isEmpty {
                        Text("\(exam.topics.count) tema\(exam.topics.count != 1 ? "s" : "")")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }

                    if let room = exam.room, !room.isEmpty {
                        Text(room)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }

                if exam.isFinished {
                    Text("Completado")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    CountdownView(date: exam.date)
                        .font(.caption)
                        .foregroundColor(exam.timeStatus.color)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(exam.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text(exam.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}
