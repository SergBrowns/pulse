import SwiftUI

struct TaskInboxSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let tasks: [TaskItem]
    let onComplete: (TaskItem) -> Void
    let onDelete: (TaskItem) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                PulseTheme.background(for: colorScheme).ignoresSafeArea()
                if tasks.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            intro
                            ForEach(tasks) { task in
                                taskCard(task)
                            }
                        }
                        .padding(18)
                    }
                }
            }
            .navigationTitle("Инбокс")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
    }

    private var intro: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Задачи без времени").font(.system(.title3, design: .rounded, weight: .bold))
                Text("Зажмите карточку и перетащите её в календарь").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(tasks.count)").font(.headline.monospacedDigit()).foregroundStyle(PulseTheme.work)
                .frame(width: 38, height: 38).background(PulseTheme.work.opacity(0.12), in: Circle())
        }
        .padding(.bottom, 4)
    }

    private func taskCard(_ task: TaskItem) -> some View {
        HStack(spacing: 13) {
            Button {
                onComplete(task)
            } label: {
                ZStack {
                    Circle().stroke(PulseTheme.accent(for: task.context).opacity(0.45), lineWidth: 1.5)
                    if task.isCompleted {
                        Circle().fill(PulseTheme.accent(for: task.context))
                        Image(systemName: "checkmark").font(.caption2.bold()).foregroundStyle(.white)
                    }
                }
                .frame(width: 25, height: 25)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title).font(.subheadline.weight(.semibold)).strikethrough(task.isCompleted)
                HStack(spacing: 8) {
                    Label("\(task.durationMinutes) мин", systemImage: "clock.fill")
                    Text(task.context == .work ? "Работа" : "Личное")
                }
                .font(.caption2.weight(.medium)).foregroundStyle(PulseTheme.accent(for: task.context))
            }
            Spacer()
            Image(systemName: "line.3.horizontal").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(15)
        .pulseCard(cornerRadius: 19, shadow: false)
        .contentShape(.rect)
        .draggable(task.id.uuidString) {
            Text(task.title).font(.caption.weight(.semibold)).padding(12).pulseCard(cornerRadius: 12)
        }
        .contextMenu {
            Button("Выполнено", systemImage: "checkmark.circle") { onComplete(task) }
            Button("Удалить", systemImage: "trash", role: .destructive) { onDelete(task) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(PulseTheme.work.opacity(0.11)).frame(width: 80, height: 80)
                Image(systemName: "checkmark.seal.fill").font(.system(size: 34)).foregroundStyle(PulseTheme.work)
            }
            Text("Всё разобрано").font(.system(.title2, design: .rounded, weight: .bold))
            Text("Новые мысли можно быстро добавить через волшебную строку внизу экрана.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(30)
    }
}
