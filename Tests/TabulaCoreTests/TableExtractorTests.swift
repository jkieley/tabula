import Foundation
import Testing
@testable import TabulaCore

struct TableExtractorTests {
    @Test func alignmentsMapFromDelimiterRow() throws {
        let tables = TableExtractor.extract(from: """
        | a | b | c | d |
        |:--|:-:|--:|---|
        | x | y | z | w |
        """)
        let table = try #require(tables.first)
        #expect(table.columns.map(\.sourceAlignment) == [.leading, .center, .trailing, nil])
    }

    @Test func shortRowsArePaddedToHeaderWidth() throws {
        let table = try #require(TableExtractor.extract(from: """
        | a | b | c |
        |---|---|---|
        | 1 |
        """).first)
        #expect(table.rows[0].cells.count == 3)
        #expect(table.rows[0].cells[1] == .empty)
    }

    @Test func captionsComeFromNearestHeading() {
        let tables = TableExtractor.extract(from: """
        | a |
        |---|
        | 1 |

        # Report
        ## Service health

        | b |
        |---|
        | 2 |

        - item

          | c |
          |---|
          | 3 |
        """)
        #expect(tables.map(\.caption) == [nil, "Service health", "Service health"])
    }

    @Test func escapedPipeAndBreaks() throws {
        let table = try #require(TableExtractor.extract(from: """
        | a | b |
        |---|---|
        | a \\| b | a<br>b |
        """).first)
        #expect(table.rows[0].cells[0].plainText == "a | b")
        #expect(table.rows[0].cells[1].plainText == "a\nb")
    }

    @Test func inlineAttributes() throws {
        let table = try #require(TableExtractor.extract(from: """
        | a | b |
        |---|---|
        | **bold** | [site](https://example.com) |
        """).first)
        let bold = table.rows[0].cells[0].text
        #expect(bold.runs.first?.inlinePresentationIntent?.contains(.stronglyEmphasized) == true)
        let link = table.rows[0].cells[1].text
        #expect(link.runs.first?.link == URL(string: "https://example.com"))
        #expect(table.rows[0].cells[1].plainText == "site")
    }

    @Test func markdownSourceIsPreserved() throws {
        let table = try #require(TableExtractor.extract(from: """
        | a | b |
        |---|---|
        | **b** \\| x | `code` |
        """).first)
        #expect(table.rows[0].cells[0].markdown == "**b** \\| x")
        #expect(table.rows[0].cells[1].markdown == "`code`")
        #expect(table.columns[0].title.markdown == "a")
    }

    @Test func noTablesGivesEmpty() {
        #expect(TableExtractor.extract(from: "# Title\n\nJust text.").isEmpty)
    }

    @Test func columnKinds() throws {
        let table = try #require(TableExtractor.extract(from: """
        | n | m | p | d | t |
        |---|---|---|---|---|
        | 1,204 | $1.5 | 12% | 2026-10-17 | 1 |
        | 9 | $20 | 3% | 2026-10-16T22:15 | x |
        """).first)
        #expect(table.columns.map(\.kind) == [.number, .number, .number, .date, .text])
        #expect(table.columns[0].alignment == .trailing)
        #expect(table.columns[3].alignment == .leading)
    }
}
