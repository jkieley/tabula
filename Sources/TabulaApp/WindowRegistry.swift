import AppKit
import TabulaCore

/// Owns every open table window plus the welcome window, and places new windows in a cascade.
final class WindowRegistry {
    private var controllers: [TableWindowController] = []
    private var welcome: WelcomeWindowController?
    private var cascadePoint: NSPoint?

    var hasTableWindows: Bool { !controllers.isEmpty }

    func open(_ urls: [URL]) {
        for url in urls {
            guard url.pathExtension == TabulaConstants.payloadExtension else {
                showAlert("Tabula opens tables sent by the tabula command.", detail: url.lastPathComponent)
                continue
            }
            let payload: TabulaPayload
            do {
                payload = try JSONDecoder().decode(TabulaPayload.self, from: Data(contentsOf: url))
                guard payload.version == TabulaPayload.currentVersion else {
                    throw CocoaError(.fileReadCorruptFile, userInfo: [
                        NSLocalizedDescriptionKey: "Unsupported payload version \(payload.version).",
                    ])
                }
            } catch {
                showAlert("Tabula couldn't open the table", detail: error.localizedDescription)
                continue
            }
            if url.deletingLastPathComponent().lastPathComponent == TabulaConstants.inboxDirectoryName {
                try? FileManager.default.removeItem(at: url)
            }
            for document in payload.documents {
                let tables = TableExtractor.extract(from: document.markdown)
                for (index, table) in tables.enumerated() {
                    let controller = TableWindowController(
                        document: document,
                        tableIndex: index,
                        tableCount: tables.count,
                        table: table,
                        onClose: { [weak self] in self?.remove($0) }
                    )
                    controllers.append(controller)
                    place(controller)
                }
            }
        }
        if hasTableWindows {
            welcome?.close()
            NSApp.activate()
        }
    }

    func showWelcome() {
        let controller = welcome ?? WelcomeWindowController(onClose: { [weak self] in self?.welcome = nil })
        welcome = controller
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    private func place(_ controller: TableWindowController) {
        guard let window = controller.window else { return }
        if let point = cascadePoint {
            cascadePoint = window.cascadeTopLeft(from: point)
        } else {
            window.center()
            cascadePoint = window.cascadeTopLeft(from: .zero)
        }
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        controller.startWatching()
    }

    private func remove(_ controller: TableWindowController) {
        controllers.removeAll { $0 === controller }
        if controllers.isEmpty { cascadePoint = nil }
    }

    private func showAlert(_ message: String, detail: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.runModal()
    }
}
