import AppKit
import Observation
import SwiftUI
import TabulaCore

enum WatchStatus: Equatable {
    case live(updated: Date)
    case paused(reason: String)
}

@Observable
final class TableViewModel {
    let document: TabulaPayload.Document
    let tableIndex: Int
    var table: TabulaTable
    var layout: ColumnLayout
    /// Row ids in display order.
    var order: [Int]
    var sort: SortState?
    var selection = RowSelection()
    var titles: WindowTitles
    var watchStatus: WatchStatus?
    var missingTableMessage: String?
    /// Row id the grid should scroll into view.
    var scrollTarget: Int?

    init(table: TabulaTable, document: TabulaPayload.Document, tableIndex: Int, tableCount: Int) {
        self.document = document
        self.tableIndex = tableIndex
        self.table = table
        layout = ColumnLayout.compute(for: table)
        order = table.rows.map(\.id)
        titles = Self.titles(for: table, document: document, tableIndex: tableIndex, tableCount: tableCount)
        watchStatus = (document.watch && document.sourcePath != nil) ? .live(updated: .now) : nil
    }

    func toggleSort(column: Int) {
        let apply = {
            self.sort = SortState.next(self.sort, clicking: column)
            self.order = TableSorter.order(of: self.table, by: self.sort)
        }
        if table.rows.count <= 500 {
            withAnimation(.snappy(duration: 0.25), apply)
        } else {
            apply()
        }
    }

    func click(row id: Int, modifier: RowSelection.ClickModifier) {
        selection.click(id, modifier: modifier, order: order)
    }

    func moveSelection(by delta: Int, extend: Bool) {
        selection.move(by: delta, extend: extend, order: order)
        scrollTarget = selection.cursor
    }

    func selectAll() {
        selection.selectAll(order: order)
    }

    func clearSelection() {
        selection.clear()
    }

    func copySelection() {
        let ids = order.filter { selection.selected.contains($0) }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.declareTypes([.string, .html, .tabularText], owner: nil)
        pasteboard.setString(TableSerializer.markdown(table, rows: ids), forType: .string)
        pasteboard.setString(TableSerializer.html(table, rows: ids), forType: .html)
        pasteboard.setString(TableSerializer.tsv(table, rows: ids), forType: .tabularText)
    }

    /// Applies a reloaded table from `--watch`.
    func replaceTable(_ table: TabulaTable, tableCount: Int) {
        self.table = table
        layout = ColumnLayout.compute(for: table)
        titles = Self.titles(for: table, document: document, tableIndex: tableIndex, tableCount: tableCount)
        if let sort, sort.column >= table.columns.count { self.sort = nil }
        order = TableSorter.order(of: table, by: sort)
        selection.clear()
        missingTableMessage = nil
    }

    /// The watched file no longer has this table; the last table is kept but hidden.
    func markMissing(_ message: String, tableCount: Int) {
        missingTableMessage = message
        selection.clear()
        titles = Self.titles(for: table, document: document, tableIndex: tableIndex, tableCount: tableCount)
    }

    private static func titles(for table: TabulaTable, document: TabulaPayload.Document, tableIndex: Int, tableCount: Int) -> WindowTitles {
        WindowTitles.make(
            overrideTitle: document.title,
            caption: table.caption,
            displayName: document.displayName,
            rowCount: table.rows.count,
            columnCount: table.columns.count,
            tableIndex: tableIndex,
            tableCount: tableCount
        )
    }
}
