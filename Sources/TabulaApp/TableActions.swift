import AppKit

/// Menu actions sent up the responder chain to the key `TableWindowController`.
@objc protocol TableActions {
    func copyRows(_ sender: Any?)
    func selectAllRows(_ sender: Any?)
    func exportCSV(_ sender: Any?)
    func exportPNG(_ sender: Any?)
    func exportPDF(_ sender: Any?)
}
