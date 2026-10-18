import Foundation
import Markdown

public enum TableExtractor {
    /// Returns every GFM table in `markdown`, in document order.
    public static func extract(from markdown: String) -> [TabulaTable] {
        let document = Document(parsing: markdown, options: [.disableSmartOpts])
        var collector = TableCollector(slicer: SourceSlicer(source: markdown))
        collector.visit(document)
        return collector.tables
    }
}

struct TableCollector: MarkupWalker {
    let slicer: SourceSlicer
    var lastHeading: String?
    var tables: [TabulaTable] = []

    init(slicer: SourceSlicer) {
        self.slicer = slicer
    }

    mutating func visitHeading(_ heading: Heading) {
        lastHeading = heading.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    mutating func visitTable(_ table: Markdown.Table) {
        tables.append(build(table))
    }

    private func build(_ table: Markdown.Table) -> TabulaTable {
        let columnCount = table.maxColumnCount
        let headerCells = padded(Array(table.head.cells).map(cell(from:)), to: columnCount)
        let rows = table.body.rows.enumerated().map { index, row in
            TabulaRow(id: index, cells: padded(Array(row.cells).map(cell(from:)), to: columnCount).map(ValueClassifier.applied(to:)))
        }
        let alignments = table.columnAlignments.map { alignment -> ColumnAlignment? in
            switch alignment {
            case .left: .leading
            case .center: .center
            case .right: .trailing
            case nil: nil
            }
        }
        let columns = (0..<columnCount).map { index in
            let source = index < alignments.count ? alignments[index] : nil
            let kind = ValueClassifier.kind(of: rows.map { $0.cells[index] })
            return TabulaColumn(
                title: headerCells[index],
                sourceAlignment: source,
                kind: kind,
                alignment: source ?? (kind == .number ? .trailing : .leading)
            )
        }
        return TabulaTable(caption: lastHeading, columns: columns, rows: rows)
    }

    private func padded(_ cells: [TabulaCell], to count: Int) -> [TabulaCell] {
        if cells.count >= count { return Array(cells.prefix(count)) }
        return cells + Array(repeating: .empty, count: count - cells.count)
    }

    private func cell(from cell: Markdown.Table.Cell) -> TabulaCell {
        if cell.colspan == 0 || cell.rowspan == 0 { return .empty }
        let text = InlineRenderer.render(cell)
        let plainText = String(text.characters)
        var markdown = slicer.slice(cell.range) ?? ""
        if markdown.isEmpty && !plainText.isEmpty {
            markdown = plainText
                .replacingOccurrences(of: "|", with: "\\|")
                .replacingOccurrences(of: "\n", with: "<br>")
        }
        return TabulaCell(text: text, plainText: plainText, markdown: markdown)
    }
}
