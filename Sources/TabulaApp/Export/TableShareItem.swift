import CoreTransferable
import TabulaCore
import UniformTypeIdentifiers

/// Shares the table as a PNG; `nonisolated` because the app target defaults to MainActor isolation.
nonisolated struct TableShareItem: Transferable {
    let table: TabulaTable
    let order: [Int]
    let titles: WindowTitles
    let isDark: Bool

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .png) { item in
            SentTransferredFile(try await TableExporter.writeSharePNG(item))
        }
    }
}
