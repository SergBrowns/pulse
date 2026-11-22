import SwiftUI

struct TimelineView: View {
    let date: Date
    let items: [PulseItem]
    let mode: ContextMode
    let privacyShieldEnabled: Bool
    let onDropTask: (UUID, Date) -> Void
    let onAddBuffer: (PulseItem) -> Void

    @State private var expandedGaps = Set<String>()
    private let calendar = Calendar.current

    var body: some View {
        SwiftUI.TimelineView(.periodic(from: .now, by: 30)) { context in
            let model = TimelineViewModel(date: date, items: items, mode: mode)
            let effectivePrivacy = privacyShieldEnabled || items.contains {
                $0.context == .work && $0.joinURL != nil && context.date >= $0.start && context.date <= $0.end
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if model.visibleItems.isEmpty {
                            emptyTimeline
                        } else {
                            ForEach(rows(for: model, now: context.date)) { row in
                                rowView(row, model: model, now: context.date, effectivePrivacy: effectivePrivacy)
                                    .id(row.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onAppear {
                    if calendar.isDateInToday(date) {
                        withAnimation(.easeOut(duration: 0.35)) { proxy.scrollTo("current-time", anchor: .center) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: Row, model: TimelineViewModel, now: Date, effectivePrivacy: Bool) -> some View {
        switch row {
        case .item(let item):
            EventCardView(
                item: item,
                privacyShieldEnabled: effectivePrivacy,
                isBackToBack: model.backToBackItemIDs.contains(item.id),
                now: now,
                onAddBuffer: { onAddBuffer(item) }
            )
        case .gap(let gap):
            gapView(gap)
        case .current(let date):
            currentTimeLine(date)
        case .hour(let date):
            hourLine(date)
        }
    }

    private func gapView(_ gap: TimelineViewModel.FreeGap) -> some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.snappy) {
                    if expandedGaps.contains(gap.id) { expandedGaps.remove(gap.id) } else { expandedGaps.insert(gap.id) }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                    Text(gap.displayText)
                    Spacer()
                    Image(systemName: expandedGaps.contains(gap.id) ? "chevron.up" : "chevron.down")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.primary.opacity(0.045), in: .rect(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .dropDestination(for: String.self) { values, _ in
                guard let raw = values.first, let id = UUID(uuidString: raw) else { return false }
                onDropTask(id, snapToQuarter(gap.start))
                HapticManager.snap()
                return true
            }

            if expandedGaps.contains(gap.id) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 6)], spacing: 6) {
                    ForEach(slots(in: gap), id: \.self) { slot in
                        Text(slot.formatted(date: .omitted, time: .shortened))
                            .font(.caption.monospacedDigit())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(.thinMaterial, in: .rect(cornerRadius: 9, style: .continuous))
                            .dropDestination(for: String.self) { values, _ in
                                guard let raw = values.first, let id = UUID(uuidString: raw) else { return false }
                                onDropTask(id, slot)
                                HapticManager.snap()
                                return true
                            }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func currentTimeLine(_ date: Date) -> some View {
        HStack(spacing: 8) {
            Text(date.formatted(date: .omitted, time: .shortened))
                .font(.caption2.bold().monospacedDigit())
                .foregroundStyle(.red)
            Circle().fill(.red).frame(width: 7, height: 7)
            Rectangle().fill(.red.opacity(0.75)).frame(height: 1)
        }
        .id("current-time")
        .accessibilityLabel("Текущее время \(date.formatted(date: .omitted, time: .shortened))")
    }

    private func hourLine(_ date: Date) -> some View {
        HStack(spacing: 8) {
            Text(date.formatted(date: .omitted, time: .shortened))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
                .frame(width: 42, alignment: .leading)
            Rectangle()
                .fill(.primary.opacity(0.08))
                .frame(height: 0.5)
        }
        .padding(.vertical, 3)
        .dropDestination(for: String.self) { values, _ in
            guard let raw = values.first, let id = UUID(uuidString: raw) else { return false }
            onDropTask(id, date)
            HapticManager.snap()
            return true
        }
    }

    private var emptyTimeline: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text("День свободен")
                .font(.system(.title3, design: .rounded, weight: .bold))
            Text("Перетащите задачу из инбокса на один из 15-минутных слотов.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 68), spacing: 8)], spacing: 8) {
                ForEach(8..<21, id: \.self) { hour in
                    let slot = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
                    Text(slot.formatted(date: .omitted, time: .shortened))
                        .font(.caption.monospacedDigit())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.primary.opacity(0.05), in: .rect(cornerRadius: 10, style: .continuous))
                        .dropDestination(for: String.self) { values, _ in
                            guard let raw = values.first, let id = UUID(uuidString: raw) else { return false }
                            onDropTask(id, slot)
                            HapticManager.snap()
                            return true
                        }
                }
            }
        }
        .padding(24)
        .pulseCard()
    }

    private func rows(for model: TimelineViewModel, now: Date) -> [Row] {
        var result: [Row] = []
        let shouldShowNow = calendar.isDate(date, inSameDayAs: now)
        var insertedNow = false
        for (index, item) in model.visibleItems.enumerated() {
            if shouldShowNow, !insertedNow, now < item.start {
                result.append(.current(now))
                insertedNow = true
            }
            if index > 0 {
                let previous = model.visibleItems[index - 1]
                if item.start.timeIntervalSince(previous.end) >= 2 * 60 * 60 {
                    result.append(.gap(.init(start: previous.end, end: item.start)))
                } else {
                    result.append(contentsOf: hourRows(from: previous.end, to: item.start))
                }
            } else {
                let dayStart = calendar.date(bySettingHour: max(6, calendar.component(.hour, from: item.start) - 1), minute: 0, second: 0, of: date) ?? date
                result.append(contentsOf: hourRows(from: dayStart.addingTimeInterval(-1), to: item.start))
            }
            result.append(.item(item))
        }
        if shouldShowNow, !insertedNow { result.append(.current(now)) }
        return result
    }

    private func hourRows(from start: Date, to end: Date) -> [Row] {
        guard end > start else { return [] }
        let startHour = calendar.dateInterval(of: .hour, for: start)?.start ?? start
        var cursor = calendar.date(byAdding: .hour, value: 1, to: startHour) ?? end
        var rows: [Row] = []
        while cursor < end, rows.count < 4 {
            rows.append(.hour(cursor))
            cursor = calendar.date(byAdding: .hour, value: 1, to: cursor) ?? end
        }
        return rows
    }

    private func slots(in gap: TimelineViewModel.FreeGap) -> [Date] {
        var result: [Date] = []
        var cursor = snapToQuarter(gap.start)
        while cursor < gap.end, result.count < 48 {
            result.append(cursor)
            cursor = calendar.date(byAdding: .minute, value: 15, to: cursor) ?? gap.end
        }
        return result
    }

    private func snapToQuarter(_ date: Date) -> Date {
        let minute = calendar.component(.minute, from: date)
        let snapped = Int((Double(minute) / 15).rounded(.up)) * 15
        let hourStart = calendar.date(bySetting: .minute, value: 0, of: date) ?? date
        return calendar.date(byAdding: .minute, value: snapped, to: hourStart) ?? date
    }

    private enum Row: Identifiable {
        case item(PulseItem)
        case gap(TimelineViewModel.FreeGap)
        case current(Date)
        case hour(Date)

        var id: String {
            switch self {
            case .item(let item): "item-\(item.id)"
            case .gap(let gap): "gap-\(gap.id)"
            case .current: "current-time"
            case .hour(let date): "hour-\(date.timeIntervalSince1970)"
            }
        }
    }
}

