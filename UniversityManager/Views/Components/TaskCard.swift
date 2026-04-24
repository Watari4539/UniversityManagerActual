import SwiftUI

struct TaskCard: View {
    let task: TaskItem
    let classStore: ClassStore
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Priority Indicator
            Rectangle()
                .fill(task.priority.color)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 6) {
                // Title and Class
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Indicador de completado (solo visual, no clickeable)
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor(task.isCompleted ? .green : .gray.opacity(0.5))
                    
                    if let classItem = classStore.findClass(by: task.classId) {
                        Circle()
                            .fill(classItem.color)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Class Name
                if let classItem = classStore.findClass(by: task.classId) {
                    Text(classItem.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Time Remaining
                CountdownView(date: task.dueDate)
                    .font(.caption)
                    .foregroundColor(task.timeStatus.color)
            }
            
            Spacer()
            
            // Due Date
            VStack(alignment: .trailing, spacing: 4) {
                Text(task.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(task.dueDate.formatted(date: .omitted, time: .shortened))
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
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// ==============================================
// CountdownView - DEBE estar en el MISMO archivo
// ==============================================

struct CountdownView: View {
    let date: Date
    @State private var timeRemaining: TimeInterval = 0
    
    var body: some View {
        let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
        
        Text(formatTimeRemaining(timeRemaining))
            .onAppear { updateTimeRemaining() }
            .onReceive(timer) { _ in updateTimeRemaining() }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = date.timeIntervalSinceNow
    }
    
    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, interval))
        
        if totalSeconds < 60 {
            return "\(totalSeconds) segundos"
        } else if totalSeconds < 3600 {
            let minutes = totalSeconds / 60
            return "\(minutes) minuto\(minutes != 1 ? "s" : "")"
        } else if totalSeconds < 86400 {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            return "\(hours)h \(minutes)m"
        } else {
            let days = totalSeconds / 86400
            let hours = (totalSeconds % 86400) / 3600
            return "\(days)d \(hours)h"
        }
    }
}
