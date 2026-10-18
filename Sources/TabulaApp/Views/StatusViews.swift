import SwiftUI
import TabulaCore

struct StatusCapsule: View {
    let model: TableViewModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.arrow.down")
            Text(sortText)
            Text("·")
            Text(countText)
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .glassEffect(.regular, in: .capsule)
    }

    private var sortText: String {
        guard let sort = model.sort, sort.column < model.table.columns.count else { return "Original order" }
        return "Sorted by \(model.table.columns[sort.column].title.plainText) \(sort.ascending ? "↑" : "↓")"
    }

    private var countText: String {
        let total = model.table.rows.count
        let selected = model.selection.selected.count
        if selected > 0 { return "\(selected) of \(total) selected" }
        return total == 1 ? "1 row" : "\(total) rows"
    }
}

struct LiveBadge: View {
    let status: WatchStatus
    let path: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isLive ? Palette.ink(.positive) : Palette.ink(.warning))
                .frame(width: 7, height: 7)
            Text(isLive ? "Live" : "Paused")
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .help(help)
    }

    private var isLive: Bool {
        if case .live = status { return true }
        return false
    }

    private var help: String {
        switch status {
        case let .live(updated):
            "Watching \(path) — updated \(updated.formatted(date: .omitted, time: .standard))"
        case let .paused(reason):
            "Paused: \(reason). Tabula keeps retrying."
        }
    }
}
