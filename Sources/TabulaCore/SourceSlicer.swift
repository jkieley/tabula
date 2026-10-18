import Foundation
import Markdown

/// Maps swift-markdown source ranges (1-based line, 1-based UTF-8 column) back to the original text.
struct SourceSlicer {
    private let bytes: [UInt8]
    private let lineStarts: [Int]

    init(source: String) {
        bytes = Array(source.utf8)
        var starts = [0]
        for (offset, byte) in bytes.enumerated() where byte == UInt8(ascii: "\n") {
            starts.append(offset + 1)
        }
        lineStarts = starts
    }

    func slice(_ range: SourceRange?) -> String? {
        guard let range,
              let lower = offset(of: range.lowerBound),
              let upper = offset(of: range.upperBound),
              lower <= upper
        else { return nil }
        var text = String(decoding: bytes[lower..<upper], as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasSuffix("|") && !text.hasSuffix("\\|") {
            text = String(text.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }

    private func offset(of location: SourceLocation) -> Int? {
        let line = location.line - 1
        guard line >= 0, line < lineStarts.count, location.column >= 1 else { return nil }
        return min(lineStarts[line] + location.column - 1, bytes.count)
    }
}
