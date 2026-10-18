import AppKit
import TabulaCore

/// Column widths measured from content (first 1,000 rows).
struct ColumnLayout: Equatable {
    /// Width of the line-number gutter, including its 1 pt separator.
    var gutterWidth: CGFloat
    var columnWidths: [CGFloat]
    var totalWidth: CGFloat

    static let measuredRowLimit = 1000

    static func compute(for table: TabulaTable) -> ColumnLayout {
        let body = NSFont.systemFont(ofSize: Metrics.bodyFontSize)
        let badge = NSFont.systemFont(ofSize: 11, weight: .semibold)
        let header = NSFont.systemFont(ofSize: 12, weight: .semibold)
        let rows = table.rows.prefix(measuredRowLimit)

        let widths = table.columns.indices.map { index -> CGFloat in
            let column = table.columns[index]
            let headerWidth = 18 + 6 + measure(column.title.plainText, header) + 4 + 10
            var widest: CGFloat = 0
            for row in rows {
                let cell = row.cells[index]
                let width: CGFloat
                if let pill = cell.badge {
                    width = measure(pill.label, badge) + 12 + 4 + 16
                } else {
                    let widestLine = cell.plainText.split(separator: "\n", omittingEmptySubsequences: false)
                        .map { measure(String($0), body) }
                        .max() ?? 0
                    width = widestLine * 1.06
                }
                widest = max(widest, width)
            }
            return min(max(max(headerWidth, widest) + 2 * Metrics.cellHorizontalPadding, 64), 384)
        }
        let digits = CGFloat(String(max(table.rows.count, 1)).count)
        let gutter = max(36, digits * 7 + 21)
        return ColumnLayout(gutterWidth: gutter, columnWidths: widths, totalWidth: gutter + widths.reduce(0, +))
    }

    private static func measure(_ text: String, _ font: NSFont) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        return ceil(NSAttributedString(string: text, attributes: [.font: font]).size().width)
    }
}
