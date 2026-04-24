import SwiftUI

struct ScheduleEditorView: View {
    @Binding var schedule: [ScheduleSlot]
    let defaultRoom: String
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedWeekdays: Set<Weekday> = []
    @State private var startHour = 8
    @State private var startMinute = 0
    @State private var endHour = 9
    @State private var endMinute = 0
    @State private var room = ""
    @State private var applyToAll = true
    
    let hours = Array(7...21)
    let minutes = [0, 15, 30, 45]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Días de la Semana")) {
                    ForEach(Weekday.scheduleDays, id: \.self) { weekday in
                        HStack {
                            Text(weekday.name)
                            Spacer()
                            if selectedWeekdays.contains(weekday) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedWeekdays.contains(weekday) {
                                selectedWeekdays.remove(weekday)
                            } else {
                                selectedWeekdays.insert(weekday)
                            }
                        }
                    }
                    
                    Toggle("Aplicar a todos los días seleccionados", isOn: $applyToAll)
                        .onChange(of: applyToAll) { newValue in
                            if newValue {
                                selectedWeekdays = Set(Weekday.scheduleDays)
                            }
                        }
                }
                
                Section(header: Text("Horario")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hora Inicio")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Picker("", selection: $startHour) {
                                    ForEach(hours, id: \.self) { hour in
                                        Text("\(hour)").tag(hour)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 80)
                                
                                Text(":")
                                
                                Picker("", selection: $startMinute) {
                                    ForEach(minutes, id: \.self) { minute in
                                        Text(String(format: "%02d", minute)).tag(minute)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 80)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Hora Fin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Picker("", selection: $endHour) {
                                    ForEach(hours, id: \.self) { hour in
                                        Text("\(hour)").tag(hour)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 80)
                                
                                Text(":")
                                
                                Picker("", selection: $endMinute) {
                                    ForEach(minutes, id: \.self) { minute in
                                        Text(String(format: "%02d", minute)).tag(minute)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 80)
                            }
                        }
                    }
                    
                    TextField("Salón", text: $room)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .onAppear {
                            room = defaultRoom
                        }
                }
                
                Section {
                    Button(action: addSchedule) {
                        HStack {
                            Spacer()
                            Image(systemName: "calendar.badge.plus")
                            Text("Agregar al Horario")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(selectedWeekdays.isEmpty || room.isEmpty)
                }
            }
            .navigationTitle("Configurar Horario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addSchedule() {
        for weekday in selectedWeekdays {
            let newSlot = ScheduleSlot(
                id: UUID(), // ← AÑADIR ID
                weekday: weekday,
                startHour: startHour,
                startMinute: startMinute,
                endHour: endHour,
                endMinute: endMinute,
                room: room.isEmpty ? defaultRoom : room
            )
            schedule.append(newSlot)
        }
        dismiss()
    }
}

// BORRA la definición duplicada al final de ClassEditView.swift
