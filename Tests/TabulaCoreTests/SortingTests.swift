import Foundation
import Testing
@testable import TabulaCore

struct SortingTests {
    private func table(_ values: [String]) throws -> TabulaTable {
        let body = values.map { "| \($0) |" }.joined(separator: "\n")
        return try #require(TableExtractor.extract(from: "| v |\n|---|\n" + body).first)
    }

    private func sortedValues(_ table: TabulaTable, ascending: Bool) -> [String] {
        TableSorter.order(of: table, by: SortState(column: 0, ascending: ascending))
            .map { table.rows[$0].cells[0].plainText }
    }

    @Test func numbersSortNumerically() throws {
        let t = try table(["310", "1,204", "9", "87", "42"])
        #expect(t.columns[0].kind == .number)
        #expect(sortedValues(t, ascending: true) == ["9", "42", "87", "310", "1,204"])
        #expect(sortedValues(t, ascending: false) == ["1,204", "310", "87", "42", "9"])
    }

    @Test func textSortsNaturally() throws {
        let t = try table(["file10", "file2", "file1"])
        #expect(sortedValues(t, ascending: true) == ["file1", "file2", "file10"])
    }

    @Test func datesSortChronologically() throws {
        let t = try table(["2026-10-17", "2026-10-16T22:15", "2026-09-30", "2026-10-16T23:59:00+02:00"])
        #expect(t.columns[0].kind == .date)
        #expect(sortedValues(t, ascending: true) == ["2026-09-30", "2026-10-16T23:59:00+02:00", "2026-10-16T22:15", "2026-10-17"])
    }

    @Test func emptyCellsSortLastBothWays() throws {
        let t = try table(["2", "", "1", " "])
        #expect(TableSorter.order(of: t, by: SortState(column: 0, ascending: true)) == [2, 0, 1, 3])
        #expect(TableSorter.order(of: t, by: SortState(column: 0, ascending: false)) == [0, 2, 1, 3])
    }

    @Test func tiesKeepSourceOrder() throws {
        let t = try table(["b", "a", "b", "a"])
        #expect(TableSorter.order(of: t, by: SortState(column: 0, ascending: true)) == [1, 3, 0, 2])
        #expect(TableSorter.order(of: t, by: SortState(column: 0, ascending: false)) == [0, 2, 1, 3])
    }

    @Test func nilSortIsSourceOrder() throws {
        let t = try table(["b", "a"])
        #expect(TableSorter.order(of: t, by: nil) == [0, 1])
    }

    @Test func nextCyclesAscendingDescendingNone() {
        let asc = SortState.next(nil, clicking: 2)
        #expect(asc == SortState(column: 2, ascending: true))
        let desc = SortState.next(asc, clicking: 2)
        #expect(desc == SortState(column: 2, ascending: false))
        #expect(SortState.next(desc, clicking: 2) == nil)
        #expect(SortState.next(desc, clicking: 0) == SortState(column: 0, ascending: true))
    }
}
