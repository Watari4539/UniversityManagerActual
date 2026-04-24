import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var classStore: ClassStore
    @State private var selectedDay: Weekday = .monday
    
    // LOGICA CLAVE: Filtra clases por semestre y luego extrae sus horarios
    var filteredSlots: [ScheduleSlot] {
        let currentClasses = classStore.classes.filter { $0.semester == classStore.currentSemester }
        
        var allSlots: [(slot: ScheduleSlot, color: Color, name: String)] = []
        
        for uiClass in currentClasses {
            for slot in uiClass.schedule where slot.weekday == selectedDay {
                allSlots.append((slot: slot, color: uiClass.color, name: uiClass.name))
            }
        }
        
        // Ordenar por hora de inicio
        return allSlots.sorted {
            ($0.slot.startHour * 60 + $0.slot.startMinute) < ($1.slot.startHour * 60 + $1.slot.startMinute)
        }.map { $0.slot } // Aquí puedes ajustar para devolver también el color si lo necesitas
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Selector de día
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Weekday.allCases, id: \.self) { day in
                            Button(action: { selectedDay = day }) {
                                Text(day.name.prefix(3))
                                    .fontWeight(selectedDay == day ? .bold : .regular)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(selectedDay == day ? Color.blue : Color.clear)
                                    .foregroundColor(selectedDay == day ? .white : .primary)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
                
                // Indicador de semestre actual (Solo lectura o informativo)
                HStack {
                    Text("Horario: Semestre \(classStore.currentSemester)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)

                if filteredSlots.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "calendar.badge.minus")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No hay clases este día")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredSlots) { slot in
                            // Buscamos la clase original para obtener el color y nombre
                            if let parentClass = classStore.classes.first(where: { c in
                                c.schedule.contains(where: { $0.id == slot.id })
                            }) {
                                ScheduleRow(slot: slot, uiClass: parentClass)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Horario")
        }
    }
}

// Componente para la fila del horario
struct ScheduleRow: View {
    let slot: ScheduleSlot
    let uiClass: UniversityClass
    
    var body: some View {
        HStack(spacing: 15) {
            VStack {
                Text(slot.startTime)
                    .font(.headline)
                Text(slot.endTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            
            Rectangle()
                .fill(uiClass.color)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading) {
                Text(uiClass.name)
                    .font(.headline)
                if !slot.room.isEmpty {
                    Label(slot.room, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
