import AppKit
import SwiftUI
import TabulaCore

/// Non-lazy rendering of a table for `ImageRenderer`. `titles` is nil on PDF continuation pages.
struct TableSnapshotView: View {
    let table: TabulaTable
    let order: [Int]
    let layout: ColumnLayout
    let titles: WindowTitles?
    let footnote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let titles {
                VStack(alignment: .leading, spacing: 4) {
                    Text(titles.title)
                        .font(.system(size: 15, weight: .semibold))
                    Text(titles.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                HeaderRowView(columns: table.columns, layout: layout, sort: nil, width: layout.totalWidth, interactive: false)
                if table.rows.isEmpty {
                    Text("No rows")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: layout.totalWidth, height: 60)
                }
                ForEach(Array(order.enumerated()), id: \.element) { position, id in
                    TableRowView(
                        row: table.rows[id],
                        columns: table.columns,
                        position: position,
                        layout: layout,
                        width: layout.totalWidth,
                        isSelected: false,
                        interactive: false
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.separator, lineWidth: 1) }
            if let footnote {
                Text(footnote)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(width: layout.totalWidth + 48, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
        .tint(Palette.violet)
    }
}
