import SwiftUI

struct TaskInboxSheet: View {
    @Environment(\.dismiss) private var dismiss
    let tasks: [TaskItem]
    let onComplete: (TaskItem) -> Void
    let onDelete: (TaskItem) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if tasks.isEmpty {
                    ContentUnavailableView(
                        "Инбокс пуст",
                        systemImage: "tray",
                        description: Text("Добавьте задачу строкой быстрого ввода.")
                    )
                } else {
                    List {
                        ForEach(tasks) { task in
                            HStack(spacing: 12) {
                                Button {
                                    onComplete(task)
                                } label: {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(task.isCompleted ? .green : .secondary)
                                }
                                .buttonStyle(.plain)

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(task.title)
                                        .strikethrough(task.isCompleted)
                                    HStack {
                                        Label("\(task.durationMinutes) мин", systemImage: "clock")
                                        Text(task.context == .work ? "Работа" : "Личное")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(PulseTheme.accent(for: task.context))
                                }
                                Spacer()
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(.rect)
                            .draggable(task.id.uuidString) {
                                Text(task.title)
                                    .padding(10)
                                    .background(.regularMaterial, in: .rect(cornerRadius: 10))
                            }
                            .swipeActions {
                                Button("Удалить", systemImage: "trash", role: .destructive) { onDelete(task) }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Задачи без времени")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

