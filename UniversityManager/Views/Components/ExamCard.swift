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
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Date Indicator
            VStack(spacing: 4) {
                Text(dayOfMonth(from: exam.date))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(monthAbbreviation(from: exam.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(weekdayAbbreviation(from: exam.date))
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
            
            VStack(alignment: .leading, spacing: 6) {
                // Title and Class
                HStack {
                    Text(exam.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let classItem = classStore.findClass(by: exam.classId) {
                        Circle()
                            .fill(classItem.color)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Class Name
                if let classItem = classStore.findClass(by: exam.classId) {
                    Text(classItem.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Topics and Time
                HStack {
                    if !exam.topics.isEmpty {
                        Text("\(exam.topics.count) tema\(exam.topics.count != 1 ? "s" : "")")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    CountdownView(date: exam.date)
                        .font(.caption)
                        .foregroundColor(exam.timeStatus.color)
                }
            }
            
            Spacer()
            
            // Time
            VStack(alignment: .trailing, spacing: 4) {
                Text(exam.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let room = exam.room {
                    Text(room)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
        }
    }
    
    private func dayOfMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func monthAbbreviation(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }
    
    private func weekdayAbbreviation(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
