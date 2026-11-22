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
                    LazyVStack(spacing: 13) {
                        timelineHeader(model: model)
                        if model.visibleItems.isEmpty {
                            emptyTimeline
                        } else {
                            ForEach(rows(for: model, now: context.date)) { row in
                                rowView(row, model: model, now: context.date, effectivePrivacy: effectivePrivacy)
                                    .id(row.id)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 26)
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
            HStack(alignment: .top, spacing: 11) {
                VStack(spacing: 4) {
                    Text(item.start.formatted(date: .omitted, time: .shortened))
                        .font(.caption.weight(.bold).monospacedDigit())
                    Text(item.end.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 9, weight: .medium).monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
                .frame(width: 43)
                .padding(.top, 14)

                EventCardView(
                    item: item,
                    privacyShieldEnabled: effectivePrivacy,
                    isBackToBack: model.backToBackItemIDs.contains(item.id),
                    now: now,
                    onAddBuffer: { onAddBuffer(item) }
                )
            }
        case .gap(let gap):
            gapView(gap)
        case .current(let date):
            currentTimeLine(date)
        case .hour(let date):
            hourLine(date)
        }
    }

    private func timelineHeader(model: TimelineViewModel) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ритм дня")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text(model.visibleItems.isEmpty ? "Пространство для важного" : "Всё на своих местах")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !model.visibleItems.isEmpty {
                Text("\(model.visibleItems.count) блоков")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.primary.opacity(0.055), in: Capsule())
            }
        }
        .padding(.bottom, 2)
    }

    private func gapView(_ gap: TimelineViewModel.FreeGap) -> some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.snappy) {
                    if expandedGaps.contains(gap.id) { expandedGaps.remove(gap.id) } else { expandedGaps.insert(gap.id) }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(PulseTheme.personal)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(gap.displayText)
                            .foregroundStyle(.primary)
                        Text("Нажмите, чтобы выбрать 15-минутный слот")
                            .font(.system(size: 9, weight: .medium))
                    }
                    Spacer()
                    Image(systemName: expandedGaps.contains(gap.id) ? "chevron.up" : "chevron.down")
                }
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(PulseTheme.personal.opacity(0.075), in: .rect(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(PulseTheme.personal.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
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
                            .background(PulseTheme.personal.opacity(0.1), in: .rect(cornerRadius: 10, style: .continuous))
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
            Circle().fill(PulseTheme.coral).frame(width: 8, height: 8)
                .shadow(color: PulseTheme.coral.opacity(0.7), radius: 5)
            Rectangle().fill(PulseTheme.coral.opacity(0.65)).frame(height: 1)
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
            ZStack {
                Circle().fill(PulseTheme.personal.opacity(0.12)).frame(width: 72, height: 72)
                Image(systemName: "leaf.fill").font(.system(size: 28)).foregroundStyle(PulseTheme.personal)
            }
            Text("День дышит свободно")
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text("Оставьте его таким или перетащите задачу из инбокса на удобное время.")
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
                        .background(.primary.opacity(0.045), in: .rect(cornerRadius: 11, style: .continuous))
                        .dropDestination(for: String.self) { values, _ in
                            guard let raw = values.first, let id = UUID(uuidString: raw) else { return false }
                            onDropTask(id, slot)
                            HapticManager.snap()
                            return true
                        }
                }
            }
        }
        .padding(26)
        .pulseCard(cornerRadius: 26)
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

