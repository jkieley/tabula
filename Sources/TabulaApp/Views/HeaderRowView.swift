import SwiftUI
import TabulaCore

struct HeaderRowView: View {
    let columns: [TabulaColumn]
    let layout: ColumnLayout
    let sort: SortState?
    let width: CGFloat
    let interactive: Bool
    var onSort: (Int) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 0) {
            Text("#")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
                .padding(.trailing, 10)
                .frame(width: layout.gutterWidth, height: Metrics.headerHeight, alignment: .trailing)
                .overlay(alignment: .trailing) { Palette.separator.frame(width: 1) }
            ForEach(columns.indices, id: \.self) { index in
                column(index)
                    .frame(width: layout.columnWidths[index], height: Metrics.headerHeight)
                    .overlay(alignment: .trailing) { Palette.separator.frame(width: 1, height: 14) }
            }
            Spacer(minLength: 0)
        }
        .frame(width: width, height: Metrics.headerHeight, alignment: .leading)
        .background(Palette.headerBackground)
        .overlay(alignment: .bottom) { Palette.headerRule.frame(height: 1) }
    }

    @ViewBuilder private func column(_ index: Int) -> some View {
        if interactive {
            Button { onSort(index) } label: { label(index) }
                .buttonStyle(.plain)
                .accessibilityLabel("Sort by \(columns[index].title.plainText)")
                .accessibilityValue(sortDescription(index))
        } else {
            label(index)
        }
    }

    private func label(_ index: Int) -> some View {
        let column = columns[index]
        return HStack(spacing: 6) {
            ColumnBadge(letter: ColumnBadge.letter(for: index))
            Text(column.title.text)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(column.alignment.textAlignment)
            if let sort, sort.column == index {
                Image(systemName: sort.ascending ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Palette.violet)
            }
        }
        .padding(.horizontal, Metrics.cellHorizontalPadding)
        .frame(width: layout.columnWidths[index], height: Metrics.headerHeight, alignment: column.alignment.frameAlignment)
        .contentShape(Rectangle())
    }

    private func sortDescription(_ index: Int) -> String {
        guard let sort, sort.column == index else { return "not sorted" }
        return sort.ascending ? "ascending" : "descending"
    }
}

struct ColumnBadge: View {
    let letter: String

    var body: some View {
        Text(letter)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.badgeInk)
            .lineLimit(1)
            .fixedSize()
            .frame(minWidth: 18, minHeight: 16)
            .background(Palette.badgeFill, in: RoundedRectangle(cornerRadius: 4))
    }

    /// Spreadsheet column letters: A…Z, AA, AB, …
    static func letter(for index: Int) -> String {
        var n = index + 1
        var letters = ""
        while n > 0 {
            let remainder = (n - 1) % 26
            letters = String(UnicodeScalar(UInt8(65 + remainder))) + letters
            n = (n - 1) / 26
        }
        return letters
    }
}
