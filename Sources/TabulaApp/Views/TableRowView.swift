import SwiftUI
import TabulaCore

struct TableRowView: View {
    let row: TabulaRow
    let columns: [TabulaColumn]
    let position: Int
    let layout: ColumnLayout
    let width: CGFloat
    let isSelected: Bool
    let interactive: Bool

    @State private var hovering = false
    @Environment(\.appearsActive) private var appearsActive

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(String(row.id + 1))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .padding(.trailing, 10)
                .frame(width: layout.gutterWidth, alignment: .trailing)
            ForEach(columns.indices, id: \.self) { index in
                CellContentView(cell: row.cells[index], column: columns[index])
                    .padding(.horizontal, Metrics.cellHorizontalPadding)
                    .padding(.vertical, Metrics.cellVerticalPadding)
                    .frame(width: layout.columnWidths[index], alignment: columns[index].alignment.frameAlignment)
            }
            Spacer(minLength: 0)
        }
        .frame(width: width, alignment: .leading)
        .frame(minHeight: Metrics.rowMinHeight)
        .background {
            ZStack(alignment: .leading) {
                position.isMultiple(of: 2) ? Palette.rowBase : Palette.rowAlternate
                if isSelected {
                    appearsActive ? Palette.selection : Palette.selectionInactive
                } else if hovering {
                    Palette.hover
                }
                Palette.separator
                    .frame(width: 1)
                    .padding(.leading, layout.gutterWidth - 1)
            }
        }
        .contentShape(Rectangle())
        .onHover { if interactive { hovering = $0 } }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
