import Foundation

/// Identifiers shared by the CLI and the app.
public enum TabulaConstants {
    public static let bundleIdentifier = "com.jkieley.Tabula"
    public static let payloadExtension = "tabula"
    public static let payloadUTI = "com.jkieley.tabula.payload"
    public static let inboxDirectoryName = "Tabula-Inbox"
    public static let stdinDisplayName = "Standard Input"
    public static let version = "1.0.0"
}

public enum ColumnAlignment: Sendable, Equatable {
    case leading, center, trailing
}

public enum ColumnKind: Sendable, Equatable {
    case number, date, text
}

public enum ValueTone: Sendable, Equatable {
    case neutral, positive, negative, changed, warning
}

public struct StatusBadge: Sendable, Equatable {
    /// Empty when the cell was a status symbol only.
    public var label: String
    public var tone: ValueTone

    public init(label: String, tone: ValueTone) {
        self.label = label
        self.tone = tone
    }
}

public struct TabulaCell: Sendable, Equatable {
    public var text: AttributedString
    public var plainText: String
    /// The cell's original markdown source, used for Markdown copy.
    public var markdown: String
    public var tone: ValueTone
    public var badge: StatusBadge?
    public var number: Double?
    public var date: Date?

    public init(
        text: AttributedString,
        plainText: String,
        markdown: String,
        tone: ValueTone = .neutral,
        badge: StatusBadge? = nil,
        number: Double? = nil,
        date: Date? = nil
    ) {
        self.text = text
        self.plainText = plainText
        self.markdown = markdown
        self.tone = tone
        self.badge = badge
        self.number = number
        self.date = date
    }

    public static let empty = TabulaCell(text: AttributedString(), plainText: "", markdown: "")
}

public struct TabulaColumn: Sendable, Equatable {
    public var title: TabulaCell
    public var sourceAlignment: ColumnAlignment?
    public var kind: ColumnKind
    public var alignment: ColumnAlignment

    public init(title: TabulaCell, sourceAlignment: ColumnAlignment?, kind: ColumnKind, alignment: ColumnAlignment) {
        self.title = title
        self.sourceAlignment = sourceAlignment
        self.kind = kind
        self.alignment = alignment
    }
}

public struct TabulaRow: Identifiable, Sendable, Equatable {
    /// 0-based index of the row in the source table.
    public var id: Int
    public var cells: [TabulaCell]

    public init(id: Int, cells: [TabulaCell]) {
        self.id = id
        self.cells = cells
    }
}

public struct TabulaTable: Sendable, Equatable {
    /// Text of the nearest heading above the table, if any.
    public var caption: String?
    public var columns: [TabulaColumn]
    public var rows: [TabulaRow]

    public init(caption: String?, columns: [TabulaColumn], rows: [TabulaRow]) {
        self.caption = caption
        self.columns = columns
        self.rows = rows
    }
}
