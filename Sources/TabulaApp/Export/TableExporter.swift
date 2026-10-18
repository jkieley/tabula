import AppKit
import SwiftUI
import TabulaCore
import UniformTypeIdentifiers

enum ExportFormat {
    case csv, png, pdf

    var contentType: UTType {
        switch self {
        case .csv: .commaSeparatedText
        case .png: .png
        case .pdf: .pdf
        }
    }

    var fileExtension: String {
        switch self {
        case .csv: "csv"
        case .png: "png"
        case .pdf: "pdf"
        }
    }
}

struct ExportError: LocalizedError {
    var errorDescription: String?
}

@MainActor
enum TableExporter {
    static let pngRowLimit = 1000
    static let pdfRowsPerPage = 40

    static func sanitizedFileName(_ title: String) -> String {
        let name = title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Table" : name
    }

    static func export(
        _ format: ExportFormat,
        table: TabulaTable,
        order: [Int],
        titles: WindowTitles,
        appearance: NSAppearance,
        to url: URL
    ) throws {
        let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        switch format {
        case .csv:
            try Data(TableSerializer.csv(table, rows: order).utf8).write(to: url, options: .atomic)
        case .png:
            try pngData(table: table, order: order, titles: titles, isDark: isDark).write(to: url, options: .atomic)
        case .pdf:
            try writePDF(table: table, order: order, titles: titles, isDark: isDark, to: url)
        }
    }

    /// Renders the share image lazily, only once the user picks a share target.
    static func writeSharePNG(_ item: TableShareItem) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Tabula-Share", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(sanitizedFileName(item.titles.title)).appendingPathExtension("png")
        try pngData(table: item.table, order: item.order, titles: item.titles, isDark: item.isDark)
            .write(to: url, options: .atomic)
        return url
    }

    static func pngData(table: TabulaTable, order: [Int], titles: WindowTitles, isDark: Bool) throws -> Data {
        let rows = Array(order.prefix(pngRowLimit))
        let hidden = order.count - rows.count
        let footnote = hidden > 0
            ? "+ \(hidden.formatted()) more rows not shown — export CSV for the full table"
            : nil
        let layout = ColumnLayout.compute(for: table)
        var data: Data?
        withAppearance(isDark: isDark) { scheme in
            let view = TableSnapshotView(table: table, order: rows, layout: layout, titles: titles, footnote: footnote)
                .environment(\.colorScheme, scheme)
            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = ProposedViewSize(width: layout.totalWidth + 48, height: nil)
            renderer.isOpaque = true
            // `renderer.cgImage` returns nil for very tall tables, so draw into our own bitmap.
            let scale: CGFloat = rows.count <= 300 ? 2 : 1
            renderer.render(rasterizationScale: scale) { size, draw in
                guard let context = CGContext(
                    data: nil,
                    width: Int((size.width * scale).rounded(.up)),
                    height: Int((size.height * scale).rounded(.up)),
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
                ) else { return }
                context.scaleBy(x: scale, y: scale)
                draw(context)
                if let image = context.makeImage() {
                    data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
                }
            }
        }
        guard let data else { throw ExportError(errorDescription: "Tabula couldn't render the table image.") }
        return data
    }

    static func writePDF(table: TabulaTable, order: [Int], titles: WindowTitles, isDark: Bool, to url: URL) throws {
        guard let context = CGContext(url as CFURL, mediaBox: nil, nil) else {
            throw ExportError(errorDescription: "Tabula couldn't create a PDF at \(url.path).")
        }
        let layout = ColumnLayout.compute(for: table)
        let pages = order.isEmpty ? [[]] : stride(from: 0, to: order.count, by: pdfRowsPerPage).map {
            Array(order[$0..<min($0 + pdfRowsPerPage, order.count)])
        }
        withAppearance(isDark: isDark) { scheme in
            for (index, rows) in pages.enumerated() {
                let page = TableSnapshotView(table: table, order: rows, layout: layout, titles: index == 0 ? titles : nil, footnote: nil)
                    .environment(\.colorScheme, scheme)
                let renderer = ImageRenderer(content: page)
                renderer.proposedSize = ProposedViewSize(width: layout.totalWidth + 48, height: nil)
                renderer.render { size, draw in
                    var box = CGRect(origin: .zero, size: size)
                    context.beginPage(mediaBox: &box)
                    draw(context)
                    context.endPage()
                }
            }
        }
        context.closePDF()
    }

    /// Renders with dynamic `NSColor`s resolved for the given appearance, matching the window on screen.
    private static func withAppearance(isDark: Bool, _ body: (ColorScheme) -> Void) {
        let appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)!
        appearance.performAsCurrentDrawingAppearance {
            body(isDark ? .dark : .light)
        }
    }
}
