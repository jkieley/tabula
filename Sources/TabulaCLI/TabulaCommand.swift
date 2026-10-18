import AppKit
import ArgumentParser
import Foundation
import TabulaCore

@main
struct TabulaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tabula",
        abstract: "Render markdown tables in native macOS windows.",
        discussion: """
        Reads markdown from the given files, or from standard input when no files are \
        given (use - for standard input). Every table found opens in its own window. \
        With --watch, windows follow their table by position as the file changes.

        Examples:
          cat report.md | tabula
          tabula report.md --title "Q3 Revenue"
          tabula --watch report.md
        """,
        version: TabulaConstants.version
    )

    @Argument(help: "Markdown files to read. Use - for standard input.")
    var files: [String] = []

    @Option(name: .shortAndLong, help: "Window title (defaults to the nearest heading above each table, else the file name).")
    var title: String?

    @Flag(name: .shortAndLong, help: "Keep windows updated when the file changes (files only).")
    var watch = false

    func validate() throws {
        if watch && (files.isEmpty || files.contains("-")) {
            throw ValidationError("--watch needs a file path; standard input can't be watched.")
        }
        if files.filter({ $0 == "-" }).count > 1 {
            throw ValidationError("Standard input (-) can only be read once.")
        }
        if files.isEmpty && isatty(STDIN_FILENO) == 1 {
            throw ValidationError("No input. Pipe markdown into tabula or pass a file path.")
        }
    }

    func run() async throws {
        var documents: [TabulaPayload.Document] = []
        for input in files.isEmpty ? ["-"] : files {
            let document = try read(input)
            if TableExtractor.extract(from: document.markdown).isEmpty {
                printError("tabula: no tables found in \(document.displayName)")
            } else {
                documents.append(document)
            }
        }
        guard !documents.isEmpty else { throw ExitCode(1) }

        guard let appURL = await AppLocator.locate() else {
            printError("tabula: Tabula.app not found — run 'make install' in the Tabula source directory")
            throw ExitCode(69)
        }

        let inbox = FileManager.default.temporaryDirectory
            .appendingPathComponent(TabulaConstants.inboxDirectoryName, isDirectory: true)
        let payloadURL = inbox
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(TabulaConstants.payloadExtension)
        do {
            try FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(TabulaPayload(documents: documents))
            try data.write(to: payloadURL, options: .atomic)
        } catch {
            printError("tabula: could not write payload: \(error.localizedDescription)")
            throw ExitCode(1)
        }

        do {
            try await handOff(payloadURL: payloadURL, appURL: appURL)
        } catch {
            try? FileManager.default.removeItem(at: payloadURL)
            printError("tabula: could not open Tabula.app: \(error.localizedDescription)")
            throw ExitCode(69)
        }
    }

    @MainActor
    private func handOff(payloadURL: URL, appURL: URL) async throws {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.addsToRecentItems = false
        _ = try await NSWorkspace.shared.open([payloadURL], withApplicationAt: appURL, configuration: configuration)
    }

    private func read(_ input: String) throws -> TabulaPayload.Document {
        let data: Data
        let displayName: String
        let sourcePath: String?
        if input == "-" {
            displayName = TabulaConstants.stdinDisplayName
            sourcePath = nil
            do {
                data = try FileHandle.standardInput.readToEnd() ?? Data()
            } catch {
                printError("tabula: cannot read \(input): \(error.localizedDescription)")
                throw ExitCode(1)
            }
        } else {
            let url = URL(fileURLWithPath: input).standardized
            displayName = url.lastPathComponent
            sourcePath = url.path
            do {
                data = try Data(contentsOf: url)
            } catch {
                printError("tabula: cannot read \(input): \(error.localizedDescription)")
                throw ExitCode(1)
            }
        }
        guard let markdown = String(data: data, encoding: .utf8) else {
            printError("tabula: \(displayName) is not valid UTF-8 text")
            throw ExitCode(1)
        }
        return TabulaPayload.Document(markdown: markdown, displayName: displayName, sourcePath: sourcePath, title: title, watch: watch)
    }

    private func printError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}
