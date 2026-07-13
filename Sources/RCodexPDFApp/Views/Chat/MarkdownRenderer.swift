import SwiftUI
import AppKit
import RCodexPDFCore

enum MarkdownSegment: Identifiable {
    case text(String)
    case code(language: String?, code: String)

    var id: String {
        switch self {
        case .text(let s): return "t-\(s.hashValue)"
        case .code(let lang, let code): return "c-\(lang ?? "")-\(code.hashValue)"
        }
    }
}

enum MarkdownParser {
    /// Splits message content on ``` fenced code blocks, keeping surrounding prose as-is.
    static func segments(from content: String) -> [MarkdownSegment] {
        var result: [MarkdownSegment] = []
        let lines = content.components(separatedBy: "\n")
        var buffer: [String] = []
        var inCode = false
        var codeLang: String?
        var codeBuffer: [String] = []

        func flushText() {
            if !buffer.isEmpty {
                result.append(.text(buffer.joined(separator: "\n")))
                buffer.removeAll()
            }
        }

        for line in lines {
            if line.hasPrefix("```") {
                if inCode {
                    result.append(.code(language: codeLang, code: codeBuffer.joined(separator: "\n")))
                    codeBuffer.removeAll()
                    inCode = false
                    codeLang = nil
                } else {
                    flushText()
                    inCode = true
                    let lang = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
                    codeLang = lang.isEmpty ? nil : lang
                }
            } else if inCode {
                codeBuffer.append(line)
            } else {
                buffer.append(line)
            }
        }
        if inCode {
            result.append(.code(language: codeLang, code: codeBuffer.joined(separator: "\n")))
        }
        flushText()
        return result
    }

    static func language(fromFenceTag tag: String?) -> ProgrammingLanguage? {
        guard let tag else { return nil }
        let normalized = tag.lowercased()
        let map: [String: ProgrammingLanguage] = [
            "c": .c, "cpp": .cpp, "c++": .cpp, "rust": .rust, "rs": .rust,
            "go": .go, "golang": .go, "python": .python, "py": .python,
            "java": .java, "javascript": .javascript, "js": .javascript,
            "typescript": .typescript, "ts": .typescript, "swift": .swift,
            "kotlin": .kotlin, "kt": .kotlin, "csharp": .csharp, "cs": .csharp, "c#": .csharp,
            "php": .php, "ruby": .ruby, "rb": .ruby, "bash": .bash, "sh": .bash, "shell": .bash
        ]
        return map[normalized]
    }
}

struct MarkdownMessageView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(MarkdownParser.segments(from: content)) { segment in
                switch segment {
                case .text(let text):
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(.init(text))
                            .textSelection(.enabled)
                    }
                case .code(let lang, let code):
                    CodeBlockView(language: lang, code: code)
                }
            }
        }
    }
}

private struct CodeBlockView: View {
    let language: String?
    let code: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(language ?? "code").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(code, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                } label: {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.secondary.opacity(0.15))

            ScrollView(.horizontal, showsIndicators: false) {
                Text(highlightedCode)
                    .font(.system(.caption, design: .monospaced))
                    .padding(8)
                    .textSelection(.enabled)
            }
            .background(Color.black.opacity(0.85))
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var highlightedCode: AttributedString {
        let storage = NSTextStorage(string: code)
        let palette = SyntaxTheme.palette(for: .dark)
        SyntaxHighlighter.highlight(storage, language: MarkdownParser.language(fromFenceTag: language), palette: palette)
        return (try? AttributedString(storage, including: \.appKit)) ?? AttributedString(code)
    }
}
