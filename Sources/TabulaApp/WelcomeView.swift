import AppKit
import SwiftUI

struct WelcomeView: View {
    private let examples = """
    cat report.md | tabula
    tabula report.md --title "Q3 Revenue"
    tabula --watch report.md
    """

    var body: some View {
        VStack(spacing: 16) {
            Text("Tabula")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("Markdown tables from your terminal, beautifully rendered.")
                .foregroundStyle(.secondary)
            Text(examples)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            Text("Every table opens in its own window.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(Palette.violet)
    }
}

final class WelcomeWindowController: NSWindowController, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 340),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: WelcomeView())
        window.titlebarAppearsTransparent = true
        window.title = "Welcome to Tabula"
        window.tabbingMode = .disallowed
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
