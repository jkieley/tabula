import SwiftUI
import TabulaCore

struct TableWindowView: View {
    let model: TableViewModel
    let onExport: (ExportFormat) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .overlay(alignment: .bottom) {
                if model.missingTableMessage == nil {
                    StatusCapsule(model: model)
                        .padding(.bottom, 14)
                }
            }
            .toolbar {
                if let status = model.watchStatus {
                    ToolbarItem {
                        LiveBadge(status: status, path: model.document.sourcePath ?? model.document.displayName)
                    }
                }
                ToolbarItem {
                    Menu {
                        Button("Export as CSV…") { onExport(.csv) }
                        Button("Export as PNG…") { onExport(.png) }
                        Button("Export as PDF…") { onExport(.pdf) }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.down")
                    }
                    .disabled(model.missingTableMessage != nil)
                }
                ToolbarItem {
                    ShareLink(
                        item: TableShareItem(table: model.table, order: model.order, titles: model.titles, isDark: colorScheme == .dark),
                        preview: SharePreview(model.titles.title, image: Image(systemName: "tablecells"))
                    )
                    .disabled(model.missingTableMessage != nil)
                }
            }
            .tint(Palette.violet)
    }

    @ViewBuilder private var content: some View {
        if let message = model.missingTableMessage {
            ContentUnavailableView("Table not found", systemImage: "tablecells.badge.ellipsis", description: Text(message))
        } else {
            TableGridView(model: model)
        }
    }
}
