import Foundation

/// JSON handed from the `tabula` CLI to Tabula.app as a `.tabula` file.
public struct TabulaPayload: Codable, Sendable, Equatable {
    public static let currentVersion = 1

    public var version: Int
    public var documents: [Document]

    public init(version: Int = TabulaPayload.currentVersion, documents: [Document]) {
        self.version = version
        self.documents = documents
    }

    public struct Document: Codable, Sendable, Equatable {
        public var markdown: String
        public var displayName: String
        /// Absolute path of the source file; nil for standard input.
        public var sourcePath: String?
        public var title: String?
        public var watch: Bool

        public init(markdown: String, displayName: String, sourcePath: String?, title: String?, watch: Bool) {
            self.markdown = markdown
            self.displayName = displayName
            self.sourcePath = sourcePath
            self.title = title
            self.watch = watch
        }
    }
}
