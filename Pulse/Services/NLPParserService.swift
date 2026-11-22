import Foundation
import NaturalLanguage

struct ParsedInput: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case event
        case inboxTask
    }

    var title: String
    var start: Date?
    var durationMinutes: Int
    var context: ContextMode
    var kind: Kind
}

struct NLPParserService: Sendable {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func parse(_ input: String, now: Date = .now) -> ParsedInput {
        let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = normalized.lowercased()
        let duration = parseDuration(lower) ?? defaultDuration(for: lower)
        let context = detectContext(lower)
        let start = parseStart(lower, now: now)
        let title = cleanedTitle(from: normalized)

        return ParsedInput(
            title: title.isEmpty ? "Новая задача" : title,
            start: start,
            durationMinutes: duration,
            context: context,
            kind: start == nil ? .inboxTask : .event
        )
    }

    private func parseDuration(_ text: String) -> Int? {
        let patterns: [(String, (Int) -> Int)] = [
            (#"(?:на|for)?\s*(\d+)\s*(?:минут(?:у|ы)?|мин\.?|minutes?|mins?)"#, { $0 }),
            (#"(?:на|for)?\s*(\d+)\s*(?:час(?:а|ов)?|ч\.?|hours?|hrs?)"#, { $0 * 60 })
        ]
        for (pattern, transform) in patterns {
            if let value = firstInteger(in: text, pattern: pattern) { return transform(value) }
        }
        return nil
    }

    private func parseStart(_ text: String, now: Date) -> Date? {
        guard let time = firstTime(in: text) else { return nil }
        var targetDay = calendar.startOfDay(for: now)

        if text.contains("послезавтра") || text.contains("day after tomorrow") {
            targetDay = calendar.date(byAdding: .day, value: 2, to: targetDay) ?? targetDay
        } else if text.contains("завтра") || text.contains("tomorrow") {
            targetDay = calendar.date(byAdding: .day, value: 1, to: targetDay) ?? targetDay
        } else if let weekday = weekday(in: text) {
            var components = DateComponents()
            components.weekday = weekday
            targetDay = calendar.nextDate(
                after: now,
                matching: components,
                matchingPolicy: .nextTime,
                direction: .forward
            ).map(calendar.startOfDay(for:)) ?? targetDay
        } else if !text.contains("сегодня") && !text.contains("today") {
            // Одно время без даты трактуем как сегодня, если оно ещё впереди, иначе как завтра.
            if let todayTime = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: targetDay), todayTime < now {
                targetDay = calendar.date(byAdding: .day, value: 1, to: targetDay) ?? targetDay
            }
        }

        return calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: targetDay)
    }

    private func firstTime(in text: String) -> (hour: Int, minute: Int)? {
        let pattern = #"(?:(?:в|at)\s*)?\b([01]?\d|2[0-3])[:.]([0-5]\d)\b|(?:(?:в|at)\s+)\b([01]?\d|2[0-3])\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }

        if let hour = integer(in: text, range: match.range(at: 1)) {
            return (hour, integer(in: text, range: match.range(at: 2)) ?? 0)
        }
        if let hour = integer(in: text, range: match.range(at: 3)) { return (hour, 0) }
        return nil
    }

    private func weekday(in text: String) -> Int? {
        let names: [(Int, [String])] = [
            (2, ["понедельник", "понедельник", "monday"]),
            (3, ["вторник", "tuesday"]),
            (4, ["среду", "среда", "wednesday"]),
            (5, ["четверг", "thursday"]),
            (6, ["пятницу", "пятница", "friday"]),
            (7, ["субботу", "суббота", "saturday"]),
            (1, ["воскресенье", "sunday"])
        ]
        return names.first { _, variants in variants.contains(where: text.contains) }?.0
    }

    private func detectContext(_ text: String) -> ContextMode {
        let work = ["созвон", "митинг", "встреч", "релиз", "дедлайн", "задач", "work", "meeting", "release", "office"]
        let personal = ["трениров", "врач", "купить", "ужин", "семь", "личн", "gym", "doctor", "dinner", "buy"]
        let workScore = work.filter(text.contains).count
        let personalScore = personal.filter(text.contains).count
        return workScore > personalScore ? .work : .personal
    }

    private func defaultDuration(for text: String) -> Int {
        let longWords = ["фокус", "воркшоп", "трениров", "workshop", "focus", "gym"]
        return longWords.contains(where: text.contains) ? 60 : 30
    }

    private func cleanedTitle(from source: String) -> String {
        let patterns = [
            #"(?i)\s+(?:сегодня|завтра|послезавтра|today|tomorrow)(?:\s+(?:в|at))?\s*\d{1,2}(?::\d{2})?"#,
            #"(?i)\s+(?:в|на)\s+(?:понедельник|вторник|среду|четверг|пятницу|субботу|воскресенье)(?:\s+в)?\s*\d{1,2}(?::\d{2})?"#,
            #"(?i)\s+(?:on\s+)?(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)(?:\s+at)?\s*\d{1,2}(?::\d{2})?"#,
            #"(?i)\s+(?:на|for)?\s*\d+\s*(?:минут(?:у|ы)?|мин\.?|minutes?|mins?|час(?:а|ов)?|ч\.?|hours?|hrs?)"#,
            #"(?i)\s+(?:в|at)\s+\d{1,2}(?::\d{2})?"#
        ]
        return patterns.reduce(source) { result, pattern in
            result.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
    }

    private func firstInteger(in text: String, pattern: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        return integer(in: text, range: match.range(at: 1))
    }

    private func integer(in text: String, range: NSRange) -> Int? {
        guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else { return nil }
        return Int(text[swiftRange])
    }
}

