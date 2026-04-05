import SwiftUI
import SwiftData
import FortachonCore

struct RoutinesSectionView: View {
    let title: String
    let routines: [RoutineM]
    let onRoutineSelect: (RoutineM) -> Void
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(isExpanded ? .degrees(90) : .zero)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                if routines.isEmpty {
                    Text("No routines yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    ForEach(routines) { routine in
                        Button {
                            onRoutineSelect(routine)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(routine.name)
                                        .fontWeight(.semibold)
                                    Text("\(routine.exercises.count) exercises")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}