import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let registry = WindowRegistry()

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.build()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        registry.open(urls)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // When the CLI launches the app, the open-files event arrives before this.
        if !registry.hasTableWindows {
            registry.showWelcome()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { registry.showWelcome() }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}
