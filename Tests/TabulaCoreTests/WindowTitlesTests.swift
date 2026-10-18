import Testing
@testable import TabulaCore

struct WindowTitlesTests {
    @Test func titlePrecedence() {
        let override = WindowTitles.make(overrideTitle: " Q3 ", caption: "Budget", displayName: "r.md", rowCount: 1, columnCount: 1, tableIndex: 0, tableCount: 1)
        #expect(override.title == "Q3")
        let caption = WindowTitles.make(overrideTitle: "  ", caption: "Budget", displayName: "r.md", rowCount: 1, columnCount: 1, tableIndex: 0, tableCount: 1)
        #expect(caption.title == "Budget")
        let name = WindowTitles.make(overrideTitle: nil, caption: nil, displayName: "r.md", rowCount: 1, columnCount: 1, tableIndex: 0, tableCount: 1)
        #expect(name.title == "r.md")
    }

    @Test func subtitleParts() {
        let full = WindowTitles.make(overrideTitle: nil, caption: "Service health", displayName: "report.md", rowCount: 5, columnCount: 6, tableIndex: 0, tableCount: 2)
        #expect(full.subtitle == "5 rows · 6 columns · report.md · Table 1 of 2")
        let single = WindowTitles.make(overrideTitle: nil, caption: nil, displayName: "Standard Input", rowCount: 1, columnCount: 1, tableIndex: 0, tableCount: 1)
        #expect(single.title == "Standard Input")
        #expect(single.subtitle == "1 row · 1 column")
        let zero = WindowTitles.make(overrideTitle: nil, caption: nil, displayName: "x", rowCount: 0, columnCount: 2, tableIndex: 0, tableCount: 1)
        #expect(zero.subtitle == "0 rows · 2 columns")
    }
}
