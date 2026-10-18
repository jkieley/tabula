import Testing
@testable import TabulaCore

struct TableSerializerTests {
    let table = TableExtractor.extract(from: """
    | Name | Note | Qty |
    |:-----|:----:|----:|
    | **API**, v2 | say "hi" | 1,204 |
    | Tab | a<br>b | 7 |
    """)[0]

    @Test func csvQuotesAndCRLF() {
        #expect(TableSerializer.csv(table, rows: [0, 1]) ==
            "Name,Note,Qty\r\n\"API, v2\",\"say \"\"hi\"\"\",\"1,204\"\r\nTab,\"a\nb\",7\r\n")
    }

    @Test func tsvReplacesTabsAndNewlines() {
        var t = table
        t.rows[1].cells[0].plainText = "T\tab"
        #expect(TableSerializer.tsv(t, rows: [1]) == "Name\tNote\tQty\nT ab\ta b\t7")
    }

    @Test func markdownKeepsAlignmentAndInlineSource() {
        #expect(TableSerializer.markdown(table, rows: [1, 0]) == """
        | Name | Note | Qty |
        | :--- | :---: | ---: |
        | Tab | a<br>b | 7 |
        | **API**, v2 | say "hi" | 1,204 |
        """)
    }

    @Test func markdownUnalignedColumns() {
        let t = TableExtractor.extract(from: "| a |\n|---|\n| 1 |")[0]
        #expect(TableSerializer.markdown(t, rows: []) == "| a |\n| --- |")
    }

    @Test func htmlEscapes() {
        var t = table
        t.rows[1].cells[0].plainText = "<a & b>"
        #expect(TableSerializer.html(t, rows: [1]) ==
            "<meta charset=\"utf-8\"><table><thead><tr><th>Name</th><th>Note</th><th>Qty</th></tr></thead>"
            + "<tbody><tr><td>&lt;a &amp; b&gt;</td><td>a<br>b</td><td>7</td></tr></tbody></table>")
        #expect(TableSerializer.html(table, rows: [0]).contains("<td>say &quot;hi&quot;</td>"))
    }
}
