import AppKit
import SwiftUI
import TabulaCore

struct TableGridView: View {
    let model: TableViewModel
    @State private var viewportWidth: CGFloat = 0
    @FocusState private var focused: Bool

    var body: some View {
        let width = max(model.layout.totalWidth, viewportWidth)
        ScrollViewReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        if model.table.rows.isEmpty {
                            Text("No rows")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .frame(width: width, height: 60)
                        }
                        ForEach(Array(model.order.enumerated()), id: \.element) { position, id in
                            let row = model.table.rows[id]
                            TableRowView(
                                row: row,
                                columns: model.table.columns,
                                position: position,
                                layout: model.layout,
                                width: width,
                                isSelected: model.selection.selected.contains(id),
                                interactive: true
                            )
                            .id(row.id)
                            .onTapGesture {
                                let flags = NSEvent.modifierFlags
                                let modifier: RowSelection.ClickModifier =
                                    flags.contains(.shift) ? .shift : (flags.contains(.command) ? .command : .none)
                                model.click(row: id, modifier: modifier)
                                focused = true
                            }
                        }
                    } header: {
                        HeaderRowView(
                            columns: model.table.columns,
                            layout: model.layout,
                            sort: model.sort,
                            width: width,
                            interactive: true,
                            onSort: { model.toggleSort(column: $0) }
                        )
                    }
                }
            }
            // A 2D ScrollView centers content shorter than the viewport, leaving a band above the rows.
            .defaultScrollAnchor(.topLeading)
            .background(Color(nsColor: .textBackgroundColor))
            .scrollEdgeEffectStyle(.hard, for: .top)
            .contentMargins(.bottom, 64, for: .scrollContent)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { viewportWidth = $0 }
            .focusable(interactions: .edit)
            .focusEffectDisabled()
            .focused($focused)
            .onAppear { focused = true }
            .onKeyPress(keys: [.upArrow, .downArrow]) { press in
                model.moveSelection(by: press.key == .upArrow ? -1 : 1, extend: press.modifiers.contains(.shift))
                return .handled
            }
            .onKeyPress(.escape) {
                model.clearSelection()
                return .handled
            }
            .onChange(of: model.scrollTarget) { _, target in
                if let target { proxy.scrollTo(target, anchor: nil) }
            }
        }
    }
}
