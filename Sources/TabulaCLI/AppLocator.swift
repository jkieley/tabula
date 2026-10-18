import AppKit
import TabulaCore

enum AppLocator {
    /// The enclosing Tabula.app when running from `Contents/Helpers/tabula`, else the registered bundle.
    @MainActor
    static func locate() -> URL? {
        if let executable = Bundle.main.executableURL?.resolvingSymlinksInPath() {
            let bundle = executable
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            if bundle.pathExtension == "app" { return bundle }
        }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: TabulaConstants.bundleIdentifier)
    }
}
