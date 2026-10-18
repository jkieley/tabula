import Foundation

/// Text formats for copy and export. `rows` are row ids in output order; every format includes the header.
public enum TableSerializer {
    public static func markdown(_ table: TabulaTable, rows: [Int]) -> String {
        let line: ([String]) -> String = { "| " + $0.joined(separator: " | ") + " |" }
        let delimiter = table.columns.map { column -> String in
            switch column.sourceAlignment {
            case .leading: ":---"
            case .center: ":---:"
            case .trailing: "---:"
            case nil: "---"
            }
        }
        var lines = [line(table.columns.map(\.title.markdown)), line(delimiter)]
        lines += rows.map { line(table.rows[$0].cells.map(\.markdown)) }
        return lines.joined(separator: "\n")
    }

    public static func tsv(_ table: TabulaTable, rows: [Int]) -> String {
        let field: (TabulaCell) -> String = { cell in
            String(cell.plainText.map { $0 == "\t" || $0 == "\r" || $0 == "\n" || $0 == "\r\n" ? " " : $0 })
        }
        return allLines(table, rows: rows)
            .map { $0.map(field).joined(separator: "\t") }
            .joined(separator: "\n")
    }

    public static func csv(_ table: TabulaTable, rows: [Int]) -> String {
        let field: (TabulaCell) -> String = { cell in
            let text = cell.plainText
            guard text.contains(where: { $0 == "," || $0 == "\"" || $0 == "\r" || $0 == "\n" || $0 == "\r\n" }) else { return text }
            return "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return allLines(table, rows: rows)
            .map { $0.map(field).joined(separator: ",") + "\r\n" }
            .joined()
    }

    public static func html(_ table: TabulaTable, rows: [Int]) -> String {
        let escape: (TabulaCell) -> String = { cell in
            cell.plainText
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "\n", with: "<br>")
        }
        var html = "<meta charset=\"utf-8\"><table><thead><tr>"
        html += table.columns.map { "<th>\(escape($0.title))</th>" }.joined()
        html += "</tr></thead><tbody>"
        for id in rows {
            html += "<tr>" + table.rows[id].cells.map { "<td>\(escape($0))</td>" }.joined() + "</tr>"
        }
        return html + "</tbody></table>"
    }

    private static func allLines(_ table: TabulaTable, rows: [Int]) -> [[TabulaCell]] {
        [table.columns.map(\.title)] + rows.map { table.rows[$0].cells }
    }
}
