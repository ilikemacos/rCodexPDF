import SwiftUI
import AppKit
import RCodexPDFCore

struct ConversationListSidebar: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search conversations", text: $viewModel.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.searchQuery) { _ in viewModel.loadConversations() }
                Button { viewModel.startNewConversation() } label: { Image(systemName: "square.and.pencil") }
                    .buttonStyle(.plain)
                    .help("New conversation")
            }
            .padding(8)

            List(viewModel.conversations, selection: Binding<UUID?>(
                get: { viewModel.activeConversation?.id },
                set: { id in
                    if let id, let conversation = viewModel.conversations.first(where: { $0.id == id }) {
                        viewModel.select(conversation)
                    }
                }
            )) { conversation in
                ConversationRow(conversation: conversation, viewModel: viewModel)
                    .tag(conversation.id)
            }
            .listStyle(.sidebar)

            Divider()
            HStack {
                Button {
                    importConversation()
                } label: { Label("Import", systemImage: "square.and.arrow.down") }
                    .buttonStyle(.plain)
                Spacer()
                if let conversation = viewModel.activeConversation {
                    Menu {
                        Button("Export as Markdown…") { exportMarkdown(conversation) }
                        Button("Export as JSON…") { exportJSON(conversation) }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .font(.caption)
            .padding(8)
        }
    }

    private func importConversation() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.importConversation(from: url)
        }
    }

    private func exportMarkdown(_ conversation: Conversation) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(conversation.title).md"
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.exportMarkdown(conversation, to: url)
        }
    }

    private func exportJSON(_ conversation: Conversation) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(conversation.title).json"
        if panel.runModal() == .OK, let url = panel.url {
            viewModel.exportJSON(conversation, to: url)
        }
    }
}

private struct ConversationRow: View {
    let conversation: Conversation
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(conversation.title).lineLimit(1)
            Text(conversation.providerID).font(.caption2).foregroundStyle(.secondary)
        }
        .contextMenu {
            Button("Delete", role: .destructive) { viewModel.delete(conversation) }
        }
    }
}
