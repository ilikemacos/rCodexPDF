import SwiftUI
import AppKit
import RCodexPDFCore

enum SidebarSection: String, CaseIterable, Identifiable {
    case pdf, editor, chat, settings

    var id: String { rawValue }

    /// Key into `Localization` — the sidebar label is looked up via this, not a hardcoded string.
    var localizationKey: String {
        switch self {
        case .pdf: return "sidebar.pdf"
        case .editor: return "sidebar.editor"
        case .chat: return "sidebar.chat"
        case .settings: return "sidebar.settings"
        }
    }

    var symbol: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .editor: return "chevron.left.forwardslash.chevron.right"
        case .chat: return "bubble.left.and.bubble.right"
        case .settings: return "gearshape"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var selectedSection: SidebarSection = .pdf

    @Published var openPDFs: [OpenPDFDocument] = []
    @Published var activePDFID: UUID?

    @Published var openCodeFiles: [OpenCodeFile] = []
    @Published var activeCodeFileID: UUID?

    @Published var chatViewModel = ChatViewModel()
    @Published var updateViewModel = UpdateViewModel()

    let settings = AppSettings.shared

    var activePDF: OpenPDFDocument? {
        openPDFs.first { $0.id == activePDFID }
    }

    var activeCodeFile: OpenCodeFile? {
        openCodeFiles.first { $0.id == activeCodeFileID }
    }

    func handleLaunchArguments() {
        let args = CommandLine.arguments.dropFirst()
        for arg in args {
            let url = URL(fileURLWithPath: arg)
            open(url: url)
        }
    }

    func open(url: URL) {
        guard url.isFileURL else { return }
        if url.pathExtension.lowercased() == "pdf" {
            openPDF(url: url)
        } else if ProgrammingLanguage.detect(from: url) != nil {
            openCodeFile(url: url)
        }
    }

    // MARK: - PDF

    func openPDF(url: URL) {
        if let existing = openPDFs.first(where: { $0.url == url }) {
            activePDFID = existing.id
            selectedSection = .pdf
            return
        }
        guard let doc = OpenPDFDocument(url: url, settings: settings) else { return }
        openPDFs.append(doc)
        activePDFID = doc.id
        selectedSection = .pdf
        settings.addRecentPDF(url)
    }

    func closePDF(_ doc: OpenPDFDocument) {
        openPDFs.removeAll { $0.id == doc.id }
        if activePDFID == doc.id {
            activePDFID = openPDFs.last?.id
        }
    }

    func presentOpenPDFPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            for url in panel.urls { openPDF(url: url) }
        }
    }

    // MARK: - Code Editor

    func openCodeFile(url: URL) {
        if let existing = openCodeFiles.first(where: { $0.url == url }) {
            activeCodeFileID = existing.id
            selectedSection = .editor
            return
        }
        let file = OpenCodeFile(url: url)
        openCodeFiles.append(file)
        activeCodeFileID = file.id
        selectedSection = .editor
        settings.addRecentFile(url)
    }

    func newCodeFile() {
        let file = OpenCodeFile(url: nil)
        openCodeFiles.append(file)
        activeCodeFileID = file.id
        selectedSection = .editor
    }

    func closeCodeFile(_ file: OpenCodeFile) {
        openCodeFiles.removeAll { $0.id == file.id }
        if activeCodeFileID == file.id {
            activeCodeFileID = openCodeFiles.last?.id
        }
    }

    func presentOpenCodeFilePanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            for url in panel.urls { openCodeFile(url: url) }
        }
    }

    // MARK: - Chat

    func newChat() {
        selectedSection = .chat
        chatViewModel.startNewConversation()
    }
}
