import SwiftUI

struct ClassesView: View {
    let resetToken: UUID
    @EnvironmentObject var classStore: ClassStore
    
    @State private var showingNewClass = false
    @State private var showingSemesterPicker = false
    
    // Filtramos usando el semestre global del Store
    var filteredClasses: [UniversityClass] {
        classStore.classes.filter { $0.semester == classStore.currentSemester }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // ENCABEZADO
                    VStack(spacing: 12) {
                        HStack {
                            Text("Clases")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            // Botón de Semestre
                            Button(action: { showingSemesterPicker = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.caption)
                                    Text("Sem \(classStore.currentSemester)")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.blue))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        Text("\(filteredClasses.count) materias registradas")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            
                            // BOTÓN ESTILO "DASHED CARD"
                            Button(action: { showingNewClass = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                    
                                    VStack(spacing: 4) {
                                        Text("Agregar Clase")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("Toca para registrar una materia")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                        .foregroundColor(.blue.opacity(0.4))
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.blue.opacity(0.02))
                                )
                            }
                            .padding(.top, 10)

                            // LISTA DE CLASES FILTRADAS
                            ForEach(filteredClasses) { classItem in
                                NavigationLink(destination: ClassDetailView(classItem: classItem)) {
                                    ClassCard(classItem: classItem) // Asegúrate de tener este componente
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 70)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewClass) {
                ClassFormView()
            }
            .sheet(isPresented: $showingSemesterPicker) {
                // Pasamos el binding directamente al Store global
                SemesterPickerSheet(selectedSemester: $classStore.currentSemester)
            }
        }
        .id(resetToken)
    }
}

struct SemesterPickerSheet: View {
    @Binding var selectedSemester: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Seleccionar Semestre")) {
                    ForEach(1...9, id: \.self) { semester in
                        Button(action: {
                            selectedSemester = semester
                            dismiss()
                        }) {
                            HStack {
                                Text("Semestre \(semester)")
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedSemester == semester {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cambiar Semestre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
    }
}
