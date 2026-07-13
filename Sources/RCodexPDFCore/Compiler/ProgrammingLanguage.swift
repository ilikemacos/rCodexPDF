import Foundation

/// Languages rCodexPDF can compile and/or run. Lua is intentionally not supported.
public enum ProgrammingLanguage: String, CaseIterable, Codable, Sendable {
    case c
    case cpp
    case rust
    case go
    case python
    case java
    case javascript
    case typescript
    case swift
    case kotlin
    case csharp
    case php
    case ruby
    case bash

    public var displayName: String {
        switch self {
        case .c: return "C"
        case .cpp: return "C++"
        case .rust: return "Rust"
        case .go: return "Go"
        case .python: return "Python"
        case .java: return "Java"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .swift: return "Swift"
        case .kotlin: return "Kotlin"
        case .csharp: return "C#"
        case .php: return "PHP"
        case .ruby: return "Ruby"
        case .bash: return "Bash"
        }
    }

    public var fileExtensions: [String] {
        switch self {
        case .c: return ["c"]
        case .cpp: return ["cpp", "cc", "cxx", "c++"]
        case .rust: return ["rs"]
        case .go: return ["go"]
        case .python: return ["py"]
        case .java: return ["java"]
        case .javascript: return ["js", "mjs", "cjs"]
        case .typescript: return ["ts"]
        case .swift: return ["swift"]
        case .kotlin: return ["kt", "kts"]
        case .csharp: return ["cs"]
        case .php: return ["php"]
        case .ruby: return ["rb"]
        case .bash: return ["sh", "bash"]
        }
    }

    public static func detect(from url: URL) -> ProgrammingLanguage? {
        let ext = url.pathExtension.lowercased()
        return ProgrammingLanguage.allCases.first { $0.fileExtensions.contains(ext) }
    }

    /// Editor syntax-highlighting mode identifier (used by the code editor's tokenizer).
    public var syntaxID: String { rawValue }
}
