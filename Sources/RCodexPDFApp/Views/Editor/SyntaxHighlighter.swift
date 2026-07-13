import AppKit
import RCodexPDFCore

/// A lightweight, dependency-free regex-based syntax highlighter. It is not a full parser, but
/// covers keywords, strings, comments, and numeric literals for every supported language, which
/// is what the vast majority of editor syntax highlighting is used for.
enum SyntaxTheme {
    struct Palette {
        let keyword: NSColor
        let string: NSColor
        let comment: NSColor
        let number: NSColor
        let type: NSColor
        let text: NSColor
        let background: NSColor
    }

    static func palette(for theme: EditorTheme) -> Palette {
        switch theme {
        case .system, .light:
            return Palette(
                keyword: NSColor(red: 0.64, green: 0.11, blue: 0.53, alpha: 1),
                string: NSColor(red: 0.77, green: 0.10, blue: 0.09, alpha: 1),
                comment: NSColor(red: 0.42, green: 0.47, blue: 0.42, alpha: 1),
                number: NSColor(red: 0.11, green: 0.0, blue: 0.81, alpha: 1),
                type: NSColor(red: 0.11, green: 0.34, blue: 0.59, alpha: 1),
                text: .textColor,
                background: .textBackgroundColor
            )
        case .dark:
            return Palette(
                keyword: NSColor(red: 0.97, green: 0.42, blue: 0.62, alpha: 1),
                string: NSColor(red: 0.99, green: 0.62, blue: 0.42, alpha: 1),
                comment: NSColor(red: 0.5, green: 0.55, blue: 0.5, alpha: 1),
                number: NSColor(red: 0.6, green: 0.79, blue: 1.0, alpha: 1),
                type: NSColor(red: 0.4, green: 0.83, blue: 0.85, alpha: 1),
                text: NSColor(white: 0.9, alpha: 1),
                background: NSColor(red: 0.11, green: 0.12, blue: 0.14, alpha: 1)
            )
        case .solarizedDark:
            return Palette(
                keyword: NSColor(red: 0.52, green: 0.60, blue: 0.0, alpha: 1),
                string: NSColor(red: 0.16, green: 0.63, blue: 0.60, alpha: 1),
                comment: NSColor(red: 0.40, green: 0.48, blue: 0.51, alpha: 1),
                number: NSColor(red: 0.83, green: 0.21, blue: 0.51, alpha: 1),
                type: NSColor(red: 0.15, green: 0.55, blue: 0.82, alpha: 1),
                text: NSColor(red: 0.51, green: 0.58, blue: 0.59, alpha: 1),
                background: NSColor(red: 0.0, green: 0.17, blue: 0.21, alpha: 1)
            )
        case .monokai:
            return Palette(
                keyword: NSColor(red: 0.98, green: 0.15, blue: 0.45, alpha: 1),
                string: NSColor(red: 0.90, green: 0.86, blue: 0.45, alpha: 1),
                comment: NSColor(red: 0.46, green: 0.44, blue: 0.37, alpha: 1),
                number: NSColor(red: 0.68, green: 0.51, blue: 1.0, alpha: 1),
                type: NSColor(red: 0.40, green: 0.85, blue: 0.94, alpha: 1),
                text: NSColor(white: 0.94, alpha: 1),
                background: NSColor(red: 0.15, green: 0.16, blue: 0.13, alpha: 1)
            )
        }
    }
}

enum SyntaxHighlighter {
    private static let keywordsByLanguage: [ProgrammingLanguage: Set<String>] = [
        .c: ["auto","break","case","char","const","continue","default","do","double","else","enum","extern","float","for","goto","if","int","long","register","return","short","signed","sizeof","static","struct","switch","typedef","union","unsigned","void","volatile","while","include","define"],
        .cpp: ["alignas","alignof","and","asm","auto","bool","break","case","catch","char","class","const","constexpr","continue","decltype","default","delete","do","double","else","enum","explicit","export","extern","false","float","for","friend","goto","if","inline","int","long","mutable","namespace","new","noexcept","nullptr","operator","private","protected","public","return","short","signed","sizeof","static","struct","switch","template","this","throw","true","try","typedef","typename","union","unsigned","using","virtual","void","volatile","while"],
        .rust: ["as","break","const","continue","crate","dyn","else","enum","extern","false","fn","for","if","impl","in","let","loop","match","mod","move","mut","pub","ref","return","self","Self","static","struct","super","trait","true","type","unsafe","use","where","while","async","await"],
        .go: ["break","case","chan","const","continue","default","defer","else","fallthrough","for","func","go","goto","if","import","interface","map","package","range","return","select","struct","switch","type","var"],
        .python: ["and","as","assert","async","await","break","class","continue","def","del","elif","else","except","False","finally","for","from","global","if","import","in","is","lambda","None","nonlocal","not","or","pass","raise","return","True","try","while","with","yield"],
        .java: ["abstract","assert","boolean","break","byte","case","catch","char","class","const","continue","default","do","double","else","enum","extends","final","finally","float","for","goto","if","implements","import","instanceof","int","interface","long","native","new","package","private","protected","public","return","short","static","strictfp","super","switch","synchronized","this","throw","throws","transient","try","void","volatile","while"],
        .javascript: ["break","case","catch","class","const","continue","debugger","default","delete","do","else","export","extends","finally","for","function","if","import","in","instanceof","let","new","return","super","switch","this","throw","try","typeof","var","void","while","with","yield","async","await","of"],
        .typescript: ["break","case","catch","class","const","continue","debugger","default","delete","do","else","export","extends","finally","for","function","if","implements","import","in","instanceof","interface","let","new","return","super","switch","this","throw","try","type","typeof","var","void","while","with","yield","async","await","of","enum","namespace","declare","readonly","public","private","protected","abstract"],
        .swift: ["associatedtype","class","deinit","enum","extension","fileprivate","func","import","init","inout","internal","let","open","operator","private","protocol","public","rethrows","static","struct","subscript","typealias","var","break","case","continue","default","defer","do","else","fallthrough","for","guard","if","in","repeat","return","switch","where","while","as","Any","catch","false","is","nil","self","Self","super","throw","throws","true","try"],
        .kotlin: ["as","break","class","continue","do","else","false","for","fun","if","in","interface","is","null","object","package","return","super","this","throw","true","try","typealias","val","var","when","while","by","catch","constructor","companion","init","override","private","protected","public","internal","data","sealed","suspend"],
        .csharp: ["abstract","as","base","bool","break","byte","case","catch","char","checked","class","const","continue","decimal","default","delegate","do","double","else","enum","event","explicit","extern","false","finally","fixed","float","for","foreach","goto","if","implicit","in","int","interface","internal","is","lock","long","namespace","new","null","object","operator","out","override","params","private","protected","public","readonly","ref","return","sbyte","sealed","short","sizeof","stackalloc","static","string","struct","switch","this","throw","true","try","typeof","uint","ulong","unchecked","unsafe","ushort","using","virtual","void","volatile","while","var","async","await"],
        .php: ["abstract","and","array","as","break","callable","case","catch","class","clone","const","continue","declare","default","do","echo","else","elseif","empty","enddeclare","endfor","endforeach","endif","endswitch","endwhile","extends","final","finally","fn","for","foreach","function","global","goto","if","implements","include","include_once","instanceof","insteadof","interface","isset","list","match","namespace","new","or","print","private","protected","public","require","require_once","return","static","switch","throw","trait","try","unset","use","var","while","xor","yield"],
        .ruby: ["BEGIN","END","alias","and","begin","break","case","class","def","defined?","do","else","elsif","end","ensure","false","for","if","in","module","next","nil","not","or","redo","rescue","retry","return","self","super","then","true","undef","unless","until","when","while","yield"],
        .bash: ["if","then","else","elif","fi","for","while","until","do","done","case","esac","function","return","local","export","readonly","shift","break","continue","in","select","time"]
    ]

    static func highlight(_ textStorage: NSTextStorage, language: ProgrammingLanguage?, palette: SyntaxTheme.Palette) {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        guard fullRange.length > 0 else { return }
        let text = textStorage.string as NSString

        textStorage.beginEditing()
        textStorage.removeAttribute(.foregroundColor, range: fullRange)
        textStorage.addAttribute(.foregroundColor, value: palette.text, range: fullRange)

        guard let language else {
            textStorage.endEditing()
            return
        }

        // Numbers
        applyPattern(#"\b\d+(\.\d+)?\b"#, color: palette.number, text: text, storage: textStorage)

        // Strings (double and single quoted, non-greedy)
        applyPattern(#""([^"\\]|\\.)*""#, color: palette.string, text: text, storage: textStorage)
        applyPattern(#"'([^'\\]|\\.)*'"#, color: palette.string, text: text, storage: textStorage)

        // Comments: // and # line comments, /* */ block comments
        if [.python, .ruby, .bash].contains(language) {
            applyPattern(#"#[^\n]*"#, color: palette.comment, text: text, storage: textStorage)
        } else {
            applyPattern(#"//[^\n]*"#, color: palette.comment, text: text, storage: textStorage)
            applyPattern(#"/\*[\s\S]*?\*/"#, color: palette.comment, text: text, storage: textStorage)
        }

        // Keywords
        if let keywords = keywordsByLanguage[language] {
            let pattern = "\\b(" + keywords.joined(separator: "|") + ")\\b"
            applyPattern(pattern, color: palette.keyword, text: text, storage: textStorage)
        }

        textStorage.endEditing()
    }

    private static func applyPattern(_ pattern: String, color: NSColor, text: NSString, storage: NSTextStorage) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let range = NSRange(location: 0, length: text.length)
        regex.enumerateMatches(in: text as String, range: range) { match, _, _ in
            guard let match else { return }
            storage.addAttribute(.foregroundColor, value: color, range: match.range)
        }
    }

    /// Simple identifier + keyword completion candidates, used by `NSTextView`'s native
    /// completion mechanism (Option-Escape / automatic-on-type) — a real, working completion
    /// source, not an LSP, but functional keyword+identifier IntelliSense-style suggestion.
    static func completions(for language: ProgrammingLanguage?, text: String, partialWord: String) -> [String] {
        guard !partialWord.isEmpty else { return [] }
        var candidates = Set<String>()
        if let language, let keywords = keywordsByLanguage[language] {
            candidates.formUnion(keywords)
        }
        let identifierRegex = try? NSRegularExpression(pattern: #"[A-Za-z_][A-Za-z0-9_]*"#)
        let nsText = text as NSString
        identifierRegex?.enumerateMatches(in: text, range: NSRange(location: 0, length: nsText.length)) { match, _, _ in
            guard let match else { return }
            candidates.insert(nsText.substring(with: match.range))
        }
        return candidates
            .filter { $0.lowercased().hasPrefix(partialWord.lowercased()) && $0 != partialWord }
            .sorted()
            .prefix(20)
            .map { $0 }
    }
}
