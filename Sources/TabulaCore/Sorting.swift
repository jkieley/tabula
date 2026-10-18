import Foundation

public struct SortState: Sendable, Equatable {
    public var column: Int
    public var ascending: Bool

    public init(column: Int, ascending: Bool) {
        self.column = column
        self.ascending = ascending
    }

    /// Cycles ascending → descending → original order for repeated clicks on one column.
    public static func next(_ current: SortState?, clicking column: Int) -> SortState? {
        guard let current, current.column == column else {
            return SortState(column: column, ascending: true)
        }
        return current.ascending ? SortState(column: column, ascending: false) : nil
    }
}

public enum TableSorter {
    /// Row ids in display order. Empty cells sort last in both directions; ties keep source order.
    public static func order(of table: TabulaTable, by sort: SortState?) -> [Int] {
        let ids = table.rows.map(\.id)
        guard let sort, sort.column < table.columns.count else { return ids }
        let kind = table.columns[sort.column].kind
        let cells = table.rows.map { $0.cells[sort.column] }
        let empty = cells.map { $0.plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let indices = Array(table.rows.indices)
        let sorted = indices.sorted { a, b in
            if empty[a] != empty[b] { return !empty[a] }
            if !empty[a] {
                let result = compare(cells[a], cells[b], kind: kind)
                if result != .orderedSame {
                    return sort.ascending ? result == .orderedAscending : result == .orderedDescending
                }
            }
            return ids[a] < ids[b]
        }
        return sorted.map { ids[$0] }
    }

    private static func compare(_ a: TabulaCell, _ b: TabulaCell, kind: ColumnKind) -> ComparisonResult {
        switch kind {
        case .number: compareOptional(a.number, b.number)
        case .date: compareOptional(a.date, b.date)
        case .text: a.plainText.localizedStandardCompare(b.plainText)
        }
    }

    private static func compareOptional<T: Comparable>(_ a: T?, _ b: T?) -> ComparisonResult {
        switch (a, b) {
        case let (a?, b?): a < b ? .orderedAscending : (a > b ? .orderedDescending : .orderedSame)
        case (nil, nil): .orderedSame
        case (nil, _): .orderedDescending
        case (_, nil): .orderedAscending
        }
    }
}
