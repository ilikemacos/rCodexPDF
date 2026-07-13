import SwiftUI
import RCodexPDFCore

struct ChatView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            ConversationListSidebar(viewModel: appState.chatViewModel)
                .frame(width: 240)
            Divider()
            ChatConversationView(viewModel: appState.chatViewModel)
        }
        .onAppear { appState.chatViewModel.loadConversations() }
    }
}

struct ChatConversationView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var showingKeyMissingAlert = false

    var body: some View {
        VStack(spacing: 0) {
            ChatProviderBar(viewModel: viewModel)
            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.activeConversation?.messages ?? []) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                        if viewModel.isStreaming {
                            MessageBubbleView(message: ChatMessage(role: .assistant, content: viewModel.streamingText.isEmpty ? "…" : viewModel.streamingText))
                                .id("streaming")
                        }
                        if let error = viewModel.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.streamingText) { _, _ in
                    withAnimation { proxy.scrollTo("streaming", anchor: .bottom) }
                }
                .onChange(of: viewModel.activeConversation?.messages.count) { _, _ in
                    if let last = viewModel.activeConversation?.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Divider()
            ChatInputBar(viewModel: viewModel)
        }
    }
}

struct ChatProviderBar: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        HStack {
            Picker("Provider", selection: Binding(
                get: { viewModel.selectedProviderID },
                set: { viewModel.changeProvider($0) }
            )) {
                ForEach(viewModel.providers, id: \.id) { provider in
                    Text(provider.displayName).tag(provider.id)
                }
            }
            .frame(width: 220)

            if let provider = viewModel.providers.first(where: { $0.id == viewModel.selectedProviderID }) {
                Picker("Model", selection: Binding(
                    get: { viewModel.selectedModel },
                    set: { viewModel.changeModel($0) }
                )) {
                    ForEach(provider.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .frame(width: 240)

                if !viewModel.keychain.hasAPIKey(for: provider.id) {
                    Label("No API key", systemImage: "key.slash")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            let usage = viewModel.totalUsage
            Text(String(format: "Total: %d tokens · $%.4f", usage.promptTokens + usage.completionTokens, usage.estimatedCostUSD))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }
}

struct ChatInputBar: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        HStack(alignment: .bottom) {
            TextEditor(text: $viewModel.inputText)
                .font(.body)
                .frame(minHeight: 36, maxHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                .onSubmit { viewModel.send() }

            if viewModel.isStreaming {
                Button { viewModel.stopStreaming() } label: {
                    Image(systemName: "stop.circle.fill").font(.title2)
                }.buttonStyle(.plain)
            } else {
                Button { viewModel.send() } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(8)
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user { Spacer(minLength: 40) }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.role == .user ? "You" : "Assistant")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                MarkdownMessageView(content: message.content)

                if let prompt = message.promptTokens, let completion = message.completionTokens {
                    HStack(spacing: 8) {
                        Text("\(prompt + completion) tokens")
                        if let cost = message.estimatedCostUSD {
                            Text(String(format: "$%.5f", cost))
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .background(message.role == .user ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if message.role != .user { Spacer(minLength: 40) }
        }
    }
}
