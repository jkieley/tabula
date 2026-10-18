import Foundation

public struct WindowTitles: Sendable, Equatable {
    public var title: String
    public var subtitle: String

    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

    /// `tableIndex` is 0-based.
    public static func make(
        overrideTitle: String?,
        caption: String?,
        displayName: String,
        rowCount: Int,
        columnCount: Int,
        tableIndex: Int,
        tableCount: Int
    ) -> WindowTitles {
        let candidates = [overrideTitle, caption].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        let title = candidates.first(where: { !$0.isEmpty }) ?? displayName
        var parts = [
            rowCount == 1 ? "1 row" : "\(rowCount) rows",
            columnCount == 1 ? "1 column" : "\(columnCount) columns",
        ]
        if displayName != title { parts.append(displayName) }
        if tableCount > 1 { parts.append("Table \(tableIndex + 1) of \(tableCount)") }
        return WindowTitles(title: title, subtitle: parts.joined(separator: " · "))
    }
}
