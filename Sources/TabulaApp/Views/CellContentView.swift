import SwiftUI
import TabulaCore

struct CellContentView: View {
    let cell: TabulaCell
    let column: TabulaColumn

    var body: some View {
        if let badge = cell.badge {
            TonePill(badge: badge)
        } else {
            Text(decorated)
                .font(.system(size: Metrics.bodyFontSize))
                .foregroundStyle(cell.tone == .positive || cell.tone == .negative ? Palette.ink(cell.tone) : .primary)
                .monospacedDigit(column.kind == .number)
                .multilineTextAlignment(column.alignment.textAlignment)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The cell text with inline-code runs given a chip background.
    private var decorated: AttributedString {
        var text = cell.text
        let codeRanges = text.runs
            .filter { $0.inlinePresentationIntent?.contains(.code) == true }
            .map(\.range)
        guard !codeRanges.isEmpty else { return text }
        var chip = AttributeContainer()
        chip[AttributeScopes.SwiftUIAttributes.BackgroundColorAttribute.self] = Palette.codeBackground
        for range in codeRanges {
            text[range].mergeAttributes(chip)
        }
        return text
    }
}

private extension View {
    @ViewBuilder func monospacedDigit(_ enabled: Bool) -> some View {
        if enabled { monospacedDigit() } else { self }
    }
}

struct TonePill: View {
    let badge: StatusBadge

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: Palette.symbol(badge.tone))
                .font(.system(size: 8, weight: .bold))
            if !badge.label.isEmpty {
                Text(badge.label)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(Palette.ink(badge.tone))
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Palette.fill(badge.tone), in: Capsule())
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(badge.label.isEmpty ? Text(String(describing: badge.tone)) : Text(badge.label))
    }
}
