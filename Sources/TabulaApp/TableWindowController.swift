import AppKit
import SwiftUI
import TabulaCore
import UniformTypeIdentifiers

final class TableWindowController: NSWindowController, NSWindowDelegate, NSMenuItemValidation, TableActions {
    /// Named `source` because `NSWindowController.document` already exists.
    let source: TabulaPayload.Document
    let tableIndex: Int
    let model: TableViewModel
    private var watcher: FileWatcher?
    private let onClose: (TableWindowController) -> Void

    init(
        document: TabulaPayload.Document,
        tableIndex: Int,
        tableCount: Int,
        table: TabulaTable,
        onClose: @escaping (TableWindowController) -> Void
    ) {
        self.source = document
        self.tableIndex = tableIndex
        self.onClose = onClose
        let model = TableViewModel(table: table, document: document, tableIndex: tableIndex, tableCount: tableCount)
        self.model = model

        var exportHandler: (ExportFormat) -> Void = { _ in }
        let hosting = NSHostingController(rootView: TableWindowView(model: model, onExport: { exportHandler($0) }))
        // `.title` bridging leaves the window titled "Untitled"; titles are synced in `syncTitles()`.
        hosting.sceneBridgingOptions = [.toolbars]
        hosting.sizingOptions = [.minSize]

        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.toolbarStyle = .unified
        window.tabbingIdentifier = "com.jkieley.Tabula.table"
        window.isRestorable = false
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 420, height: 260)

        let visible = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        let width = min(max(model.layout.totalWidth, 480), 0.85 * visible.width)
        let height = min(max(52 + 34 + 30 * CGFloat(min(table.rows.count, 30)) + 64, 300), 0.8 * visible.height)
        window.setContentSize(NSSize(width: width, height: height))

        super.init(window: window)
        window.delegate = self
        exportHandler = { [weak self] in self?.export($0) }
        syncTitles()

        if document.watch, let path = document.sourcePath {
            watcher = FileWatcher(
                url: URL(fileURLWithPath: path),
                onChange: { [weak self] in self?.reloadFromDisk() },
                onUnavailable: { [weak model] reason in model?.watchStatus = .paused(reason: reason) }
            )
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Mirrors `model.titles` into the window, re-registering after each change.
    private func syncTitles() {
        let titles = withObservationTracking { model.titles } onChange: { [weak self] in
            Task { @MainActor in self?.syncTitles() }
        }
        window?.title = titles.title
        window?.subtitle = titles.subtitle
    }

    /// Called once the window is on screen.
    func startWatching() {
        watcher?.start()
    }

    // MARK: NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        watcher?.stop()
        onClose(self)
    }

    // MARK: Menu actions

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let present = model.missingTableMessage == nil
        switch menuItem.action {
        case #selector(copyRows(_:)): return present && !model.selection.selected.isEmpty
        case #selector(selectAllRows(_:)): return present && !model.table.rows.isEmpty
        case #selector(exportCSV(_:)), #selector(exportPNG(_:)), #selector(exportPDF(_:)): return present
        default: return true
        }
    }

    @objc func copyRows(_ sender: Any?) { model.copySelection() }
    @objc func selectAllRows(_ sender: Any?) { model.selectAll() }
    @objc func exportCSV(_ sender: Any?) { export(.csv) }
    @objc func exportPNG(_ sender: Any?) { export(.png) }
    @objc func exportPDF(_ sender: Any?) { export(.pdf) }

    // MARK: Export

    func export(_ format: ExportFormat) {
        guard let window, model.missingTableMessage == nil else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format.contentType]
        panel.nameFieldStringValue = TableExporter.sanitizedFileName(model.titles.title) + "." + format.fileExtension
        panel.beginSheetModal(for: window) { [weak self] response in
            guard response == .OK, let url = panel.url, let self else { return }
            do {
                try TableExporter.export(
                    format,
                    table: self.model.table,
                    order: self.model.order,
                    titles: self.model.titles,
                    appearance: window.effectiveAppearance,
                    to: url
                )
            } catch {
                NSAlert(error: error).beginSheetModal(for: window)
            }
        }
    }

    // MARK: Watch

    private func reloadFromDisk() {
        guard let path = source.sourcePath else { return }
        let name = source.displayName
        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            model.watchStatus = .paused(reason: error.localizedDescription)
            return
        }
        guard let text = String(data: data, encoding: .utf8) else {
            model.watchStatus = .paused(reason: "\(name) is not valid UTF-8 text")
            return
        }
        let tables = TableExtractor.extract(from: text)
        if tableIndex < tables.count {
            model.replaceTable(tables[tableIndex], tableCount: tables.count)
        } else {
            model.markMissing("Table \(tableIndex + 1) is no longer in \(name).", tableCount: tables.count)
        }
        model.watchStatus = .live(updated: .now)
    }
}
