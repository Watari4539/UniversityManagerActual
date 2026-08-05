import SwiftUI

struct ScheduleEditorView: View {
    @Binding var schedule: [ScheduleSlot]
    let defaultRoom: String
    let editingSlot: ScheduleSlot?
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

    private var isEditing: Bool {
        editingSlot != nil
    }

    init(schedule: Binding<[ScheduleSlot]>, defaultRoom: String, editingSlot: ScheduleSlot? = nil) {
        self._schedule = schedule
        self.defaultRoom = defaultRoom
        self.editingSlot = editingSlot

        if let editingSlot {
            _selectedWeekdays = State(initialValue: [editingSlot.weekday])
            _startHour = State(initialValue: editingSlot.startHour)
            _startMinute = State(initialValue: editingSlot.startMinute)
            _endHour = State(initialValue: editingSlot.endHour)
            _endMinute = State(initialValue: editingSlot.endMinute)
            _room = State(initialValue: editingSlot.room)
        }
    }
    
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
                            if isEditing {
                                selectedWeekdays = [weekday]
                            } else if selectedWeekdays.contains(weekday) {
                                selectedWeekdays.remove(weekday)
                            } else {
                                selectedWeekdays.insert(weekday)
                            }
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
                            if room.isEmpty {
                                room = defaultRoom
                            }
                        }
                }
                
                Section {
                    Button(action: saveSchedule) {
                        HStack {
                            Spacer()
                            Image(systemName: isEditing ? "checkmark.circle.fill" : "calendar.badge.plus")
                            Text(isEditing ? "Guardar Horario" : "Agregar al Horario")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(selectedWeekdays.isEmpty || room.isEmpty)
                }
            }
            .navigationTitle(isEditing ? "Editar Horario" : "Configurar Horario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                            }
        }
    }
    
    private func saveSchedule() {
        if let editingSlot, let weekday = selectedWeekdays.first {
            let updatedSlot = ScheduleSlot(
                id: editingSlot.id,
                weekday: weekday,
                startHour: startHour,
                startMinute: startMinute,
                endHour: endHour,
                endMinute: endMinute,
                room: room.isEmpty ? defaultRoom : room
            )

            if let index = schedule.firstIndex(where: { $0.id == editingSlot.id }) {
                schedule[index] = updatedSlot
            }

            dismiss()
            return
        }

        for weekday in selectedWeekdays {
            let newSlot = ScheduleSlot(
                id: UUID(),
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
