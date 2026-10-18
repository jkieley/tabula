import AppKit

enum MainMenu {
    static func build() -> NSMenu {
        let main = NSMenu()

        let app = submenu(in: main, title: "Tabula")
        app.addItem(item("About Tabula", #selector(NSApplication.orderFrontStandardAboutPanel(_:))))
        app.addItem(.separator())
        app.addItem(item("Hide Tabula", #selector(NSApplication.hide(_:)), "h"))
        app.addItem(item("Hide Others", #selector(NSApplication.hideOtherApplications(_:)), "h", [.command, .option]))
        app.addItem(item("Show All", #selector(NSApplication.unhideAllApplications(_:))))
        app.addItem(.separator())
        app.addItem(item("Quit Tabula", #selector(NSApplication.terminate(_:)), "q"))

        let file = submenu(in: main, title: "File")
        file.addItem(item("Close", #selector(NSWindow.performClose(_:)), "w"))
        file.addItem(.separator())
        file.addItem(item("Export as CSV…", #selector(TableActions.exportCSV(_:))))
        file.addItem(item("Export as PNG…", #selector(TableActions.exportPNG(_:))))
        file.addItem(item("Export as PDF…", #selector(TableActions.exportPDF(_:))))

        let edit = submenu(in: main, title: "Edit")
        edit.addItem(item("Copy", #selector(TableActions.copyRows(_:)), "c"))
        edit.addItem(item("Select All", #selector(TableActions.selectAllRows(_:)), "a"))

        let view = submenu(in: main, title: "View")
        view.addItem(item("Enter Full Screen", #selector(NSWindow.toggleFullScreen(_:)), "f", [.command, .control]))

        let window = submenu(in: main, title: "Window")
        window.addItem(item("Minimize", #selector(NSWindow.performMiniaturize(_:)), "m"))
        window.addItem(item("Zoom", #selector(NSWindow.performZoom(_:))))
        window.addItem(.separator())
        window.addItem(item("Bring All to Front", #selector(NSApplication.arrangeInFront(_:))))
        NSApp.windowsMenu = window

        return main
    }

    private static func submenu(in main: NSMenu, title: String) -> NSMenu {
        let menu = NSMenu(title: title)
        let holder = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        holder.submenu = menu
        main.addItem(holder)
        return menu
    }

    /// Items have a nil target so actions travel the responder chain.
    private static func item(
        _ title: String,
        _ action: Selector,
        _ key: String = "",
        _ modifiers: NSEvent.ModifierFlags = .command
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        if !key.isEmpty { item.keyEquivalentModifierMask = modifiers }
        return item
    }
}
