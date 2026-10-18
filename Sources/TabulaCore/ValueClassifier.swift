import Foundation

enum ExplicitSign: Sendable, Equatable {
    case plus, minus
}

/// Detects numbers, ISO dates and status values in cell text.
enum ValueClassifier {
    // MARK: Numbers

    static func parseNumber(_ s: String) -> (value: Double, sign: ExplicitSign?)? {
        var chars = Substring(s.trimmingCharacters(in: .whitespacesAndNewlines))
        var sign: ExplicitSign?
        if let first = chars.first {
            switch first {
            case "+": sign = .plus
            case "-", "\u{2212}": sign = .minus
            default: break
            }
            if sign != nil {
                chars = chars.dropFirst().drop(while: { $0 == " " })
            }
        }
        if let first = chars.first, "$€£¥₹".contains(first) {
            chars = chars.dropFirst()
        }
        if chars.last == "%" {
            chars = chars.dropLast()
            while chars.last == " " { chars = chars.dropLast() }
        }
        guard let magnitude = parseDecimal(chars) else { return nil }
        return (sign == .minus ? -magnitude : magnitude, sign)
    }

    /// Digits with optional comma grouping (1–3 digits, then groups of exactly 3) and an optional fraction.
    private static func parseDecimal(_ s: Substring) -> Double? {
        guard !s.isEmpty else { return nil }
        let parts = s.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integer = parts[0]
        let isDigits: (Substring) -> Bool = { !$0.isEmpty && $0.allSatisfy { $0.isASCII && $0.isNumber } }
        if parts.count == 2 {
            guard isDigits(parts[1]) else { return nil }
        }
        var digits = ""
        if !integer.isEmpty {
            let groups = integer.split(separator: ",", omittingEmptySubsequences: false)
            for (index, group) in groups.enumerated() {
                guard isDigits(group) else { return nil }
                if groups.count > 1 {
                    if index == 0 ? group.count > 3 : group.count != 3 { return nil }
                }
                digits += group
            }
        } else if parts.count < 2 {
            return nil
        }
        if parts.count == 2 { digits += "." + parts[1] }
        if digits.hasPrefix(".") { digits = "0" + digits }
        return Double(digits)
    }

    // MARK: Dates

    static func parseDate(_ s: String) -> Date? {
        var scanner = CharScanner(Array(s.trimmingCharacters(in: .whitespacesAndNewlines)))
        guard let year = scanner.digits(4), scanner.take("-"),
              let month = scanner.digits(2), scanner.take("-"),
              let day = scanner.digits(2)
        else { return nil }
        var components = DateComponents(year: year, month: month, day: day, hour: 0, minute: 0, second: 0)
        var timeZone = TimeZone(identifier: "UTC")!
        if !scanner.atEnd {
            guard scanner.take("T") || scanner.take(" "),
                  let hour = scanner.digits(2), scanner.take(":"),
                  let minute = scanner.digits(2)
            else { return nil }
            components.hour = hour
            components.minute = minute
            if scanner.take(":") {
                guard let second = scanner.digits(2) else { return nil }
                components.second = second
                if scanner.take(".") {
                    guard let fraction = scanner.digitRun() else { return nil }
                    components.nanosecond = Int((Double("0.\(fraction)") ?? 0) * 1_000_000_000)
                }
            }
            if scanner.take("Z") {
                // UTC
            } else if let sign = scanner.peek, sign == "+" || sign == "-" {
                scanner.advance()
                guard let offsetHours = scanner.digits(2) else { return nil }
                _ = scanner.take(":")
                guard let offsetMinutes = scanner.digits(2), offsetHours <= 23, offsetMinutes <= 59 else { return nil }
                let seconds = (offsetHours * 3600 + offsetMinutes * 60) * (sign == "-" ? -1 : 1)
                guard let zone = TimeZone(secondsFromGMT: seconds) else { return nil }
                timeZone = zone
            }
        }
        guard scanner.atEnd else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        components.timeZone = timeZone
        guard let date = calendar.date(from: components) else { return nil }
        let check = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        guard check.year == components.year, check.month == components.month, check.day == components.day,
              check.hour == components.hour, check.minute == components.minute, check.second == components.second
        else { return nil }
        return date
    }

    private struct CharScanner {
        let chars: [Character]
        var index = 0

        init(_ chars: [Character]) { self.chars = chars }

        var atEnd: Bool { index >= chars.count }
        var peek: Character? { atEnd ? nil : chars[index] }
        mutating func advance() { index += 1 }

        mutating func take(_ c: Character) -> Bool {
            guard peek == c else { return false }
            index += 1
            return true
        }

        mutating func digits(_ count: Int) -> Int? {
            guard index + count <= chars.count else { return nil }
            let slice = chars[index..<index + count]
            guard slice.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
            index += count
            return Int(String(slice))
        }

        mutating func digitRun() -> String? {
            let start = index
            while let c = peek, c.isASCII, c.isNumber { index += 1 }
            return index > start ? String(chars[start..<index]) : nil
        }
    }

    // MARK: Status

    private static let symbols: [Character: ValueTone] = {
        var map: [Character: ValueTone] = [:]
        for c in ["✓", "✔", "✅", "☑", "🟢"] as [Character] { map[c] = .positive }
        for c in ["✗", "✘", "❌", "✖", "🔴", "⛔"] as [Character] { map[c] = .negative }
        for c in ["⚠", "🟡", "🟠"] as [Character] { map[c] = .warning }
        for c in ["✎", "✏", "🔵"] as [Character] { map[c] = .changed }
        return map
    }()

    private static let keywords: [String: ValueTone] = {
        var map: [String: ValueTone] = [:]
        let groups: [(ValueTone, [String])] = [
            (.positive, ["yes", "true", "pass", "passed", "passing", "ok", "success", "succeeded", "done", "complete", "completed", "added", "enabled", "active", "online", "healthy", "approved", "merged", "resolved", "up"]),
            (.negative, ["no", "false", "fail", "failed", "failing", "failure", "error", "errored", "removed", "deleted", "disabled", "inactive", "offline", "unhealthy", "rejected", "blocked", "broken", "down", "missing"]),
            (.changed, ["changed", "modified", "updated", "renamed", "moved", "edited"]),
            (.warning, ["warn", "warning", "pending", "wip", "in progress", "skipped", "partial", "degraded", "flaky", "draft", "todo", "deprecated"]),
        ]
        for (tone, words) in groups {
            for word in words { map[word] = tone }
        }
        return map
    }()

    static func classify(_ plainText: String) -> (tone: ValueTone, badge: StatusBadge?) {
        let t = String(plainText.unicodeScalars.filter { $0 != "\u{FE0F}" })
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return (.neutral, nil) }

        var symbolTone: ValueTone?
        var word = t
        if let first = t.first, let tone = symbols[first] {
            symbolTone = tone
            word = String(t.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let last = t.last, let tone = symbols[last] {
            symbolTone = tone
            word = String(t.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var label = Substring(word)
        while let last = label.last, last == "." || last == "!" { label = label.dropLast() }
        let key = label.lowercased()
        if let tone = keywords[key] {
            return (tone, StatusBadge(label: String(label), tone: tone))
        }
        if let symbolTone {
            if key.isEmpty { return (symbolTone, StatusBadge(label: "", tone: symbolTone)) }
            if word.count <= 24 { return (symbolTone, StatusBadge(label: word, tone: symbolTone)) }
            return (.neutral, nil)
        }
        if let number = parseNumber(t), let sign = number.sign, number.value != 0 {
            return (sign == .plus ? .positive : .negative, nil)
        }
        return (.neutral, nil)
    }

    // MARK: Cells and columns

    static func applied(to cell: TabulaCell) -> TabulaCell {
        var cell = cell
        let (tone, badge) = classify(cell.plainText)
        cell.tone = tone
        cell.badge = badge
        cell.number = parseNumber(cell.plainText)?.value
        cell.date = parseDate(cell.plainText)
        return cell
    }

    static func kind(of cells: [TabulaCell]) -> ColumnKind {
        let filled = cells.filter { !$0.plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !filled.isEmpty else { return .text }
        if filled.allSatisfy({ $0.number != nil }) { return .number }
        if filled.allSatisfy({ $0.date != nil }) { return .date }
        return .text
    }
}
