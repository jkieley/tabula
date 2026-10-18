import Foundation
import Markdown

/// Converts a table cell's inline markup into a Foundation-only `AttributedString`.
enum InlineRenderer {
    static func render(_ container: some Markup) -> AttributedString {
        var result = AttributedString()
        append(children: container, intent: [], link: nil, into: &result)
        return result
    }

    private static func append(children parent: some Markup, intent: InlinePresentationIntent, link: URL?, into result: inout AttributedString) {
        for child in parent.children {
            append(child, intent: intent, link: link, into: &result)
        }
    }

    private static func append(_ node: any Markup, intent: InlinePresentationIntent, link: URL?, into result: inout AttributedString) {
        switch node {
        case let text as Markdown.Text:
            result += run(text.string, intent: intent, link: link)
        case let emphasis as Emphasis:
            append(children: emphasis, intent: intent.union(.emphasized), link: link, into: &result)
        case let strong as Strong:
            append(children: strong, intent: intent.union(.stronglyEmphasized), link: link, into: &result)
        case let strike as Strikethrough:
            append(children: strike, intent: intent.union(.strikethrough), link: link, into: &result)
        case let code as InlineCode:
            result += run(code.code, intent: intent.union(.code), link: link)
        case let anchor as Markdown.Link:
            let url = anchor.destination.flatMap { URL(string: $0) }
            append(children: anchor, intent: intent, link: url, into: &result)
        case let image as Markdown.Image:
            result += run(image.plainText, intent: intent, link: nil)
        case is SoftBreak:
            result += run(" ", intent: intent, link: link)
        case is LineBreak:
            result += run("\n", intent: intent, link: link)
        case let html as InlineHTML:
            result += run(isLineBreakTag(html.rawHTML) ? "\n" : html.rawHTML, intent: intent, link: link)
        default:
            result += run((node as? any PlainTextConvertibleMarkup)?.plainText ?? node.format(), intent: intent, link: link)
        }
    }

    private static func run(_ string: String, intent: InlinePresentationIntent, link: URL?) -> AttributedString {
        var run = AttributedString(string)
        if !intent.isEmpty { run.inlinePresentationIntent = intent }
        if let link { run.link = link }
        return run
    }

    static func isLineBreakTag(_ html: String) -> Bool {
        switch html.lowercased() {
        case "<br>", "<br/>", "<br />": true
        default: false
        }
    }
}
