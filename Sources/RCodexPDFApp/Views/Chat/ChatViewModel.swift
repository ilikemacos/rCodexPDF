import Foundation
import RCodexPDFCore

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var activeConversation: Conversation?
    @Published var inputText: String = ""
    @Published var isStreaming = false
    @Published var streamingText = ""
    @Published var errorMessage: String?
    @Published var searchQuery: String = ""
    @Published var selectedProviderID: String
    @Published var selectedModel: String

    private let controller = ChatController()
    private let history = ChatHistoryStore.shared
    private let settings = AppSettings.shared
    let keychain = KeychainStore()
    private var streamTask: Task<Void, Never>?

    var providers: [any AIProvider] { AIProviderRegistry.all }

    init() {
        let defaultProviderID = AppSettings.shared.defaultAIProvider
        self.selectedProviderID = defaultProviderID
        let provider = AIProviderRegistry.provider(withID: defaultProviderID) ?? AIProviderRegistry.claude
        self.selectedModel = AppSettings.shared.selectedModel(forProvider: provider.id) ?? provider.defaultModel
        loadConversations()
    }

    func loadConversations() {
        conversations = searchQuery.isEmpty ? history.loadAll() : history.search(searchQuery)
    }

    func startNewConversation() {
        let conversation = Conversation(providerID: selectedProviderID, model: selectedModel)
        activeConversation = conversation
        streamingText = ""
        errorMessage = nil
    }

    func select(_ conversation: Conversation) {
        activeConversation = conversation
        selectedProviderID = conversation.providerID
        selectedModel = conversation.model
        streamingText = ""
        errorMessage = nil
    }

    func delete(_ conversation: Conversation) {
        try? history.delete(conversation.id)
        loadConversations()
        if activeConversation?.id == conversation.id {
            activeConversation = nil
        }
    }

    func changeProvider(_ id: String) {
        selectedProviderID = id
        settings.defaultAIProvider = id
        if let provider = AIProviderRegistry.provider(withID: id) {
            selectedModel = settings.selectedModel(forProvider: id) ?? provider.defaultModel
        }
    }

    func changeModel(_ model: String) {
        selectedModel = model
        settings.setSelectedModel(model, forProvider: selectedProviderID)
    }

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }
        inputText = ""
        errorMessage = nil

        if activeConversation == nil {
            activeConversation = Conversation(providerID: selectedProviderID, model: selectedModel)
        }
        guard var conversation = activeConversation else { return }
        conversation.providerID = selectedProviderID
        conversation.model = selectedModel

        streamingText = ""
        isStreaming = true

        streamTask = Task {
            do {
                let stream = try controller.send(userText: text, in: &conversation)
                await MainActor.run { self.activeConversation = conversation }

                var promptTokens = 0
                var completionTokens = 0
                for try await event in stream {
                    switch event {
                    case .textDelta(let delta):
                        await MainActor.run { self.streamingText += delta }
                    case .usage(let prompt, let completion):
                        promptTokens += prompt
                        completionTokens += completion
                    case .finished:
                        break
                    }
                }

                let finalText = await MainActor.run { self.streamingText }
                try controller.finish(
                    conversation: &conversation,
                    assistantText: finalText,
                    promptTokens: promptTokens,
                    completionTokens: completionTokens
                )
                await MainActor.run {
                    self.activeConversation = conversation
                    self.streamingText = ""
                    self.isStreaming = false
                    self.loadConversations()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isStreaming = false
                }
            }
        }
    }

    func stopStreaming() {
        streamTask?.cancel()
        isStreaming = false
    }

    func exportMarkdown(_ conversation: Conversation, to url: URL) {
        try? history.exportMarkdown(conversation, to: url)
    }

    func exportJSON(_ conversation: Conversation, to url: URL) {
        try? history.exportJSON(conversation, to: url)
    }

    @discardableResult
    func importConversation(from url: URL) -> Conversation? {
        let imported = try? history.importJSON(from: url)
        loadConversations()
        return imported
    }

    var totalUsage: TotalTokenUsage { history.totalUsage() }
}
