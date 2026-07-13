import Foundation

/// Orchestrates sending a message through the selected provider, persisting the conversation,
/// and reporting incremental text + final usage back to a caller (GUI view model or CLI loop).
public final class ChatController: @unchecked Sendable {
    private let keychain: KeychainStore
    private let settings: AppSettings
    private let history: ChatHistoryStore

    public init(
        keychain: KeychainStore = KeychainStore(),
        settings: AppSettings = .shared,
        history: ChatHistoryStore = .shared
    ) {
        self.keychain = keychain
        self.settings = settings
        self.history = history
    }

    public func resolveProvider(id: String) -> (any AIProvider)? {
        AIProviderRegistry.provider(withID: id)
    }

    public func modelInUse(for provider: any AIProvider) -> String {
        settings.selectedModel(forProvider: provider.id) ?? provider.defaultModel
    }

    /// Sends `userText` in the context of `conversation`, appends the user message immediately,
    /// then streams the assistant's reply. Returns the async stream of text deltas; call
    /// `finish(conversation:assistantText:promptTokens:completionTokens:)` when the stream ends
    /// to persist the completed exchange.
    public func send(
        userText: String,
        in conversation: inout Conversation
    ) throws -> AsyncThrowingStream<AIStreamEvent, Error> {
        guard let provider = resolveProvider(id: conversation.providerID) else {
            throw AIProviderError.invalidResponse("Unknown provider \(conversation.providerID)")
        }
        guard let apiKey = keychain.getAPIKey(for: provider.id), !apiKey.isEmpty else {
            throw AIProviderError.missingAPIKey
        }

        let userMessage = ChatMessage(role: .user, content: userText)
        conversation.messages.append(userMessage)
        try history.save(conversation)

        let baseURLOverride = settings.baseURLOverride(forProvider: provider.id)
        return provider.streamChat(
            messages: conversation.messages,
            model: conversation.model,
            apiKey: apiKey,
            baseURLOverride: baseURLOverride
        )
    }

    public func finish(
        conversation: inout Conversation,
        assistantText: String,
        promptTokens: Int,
        completionTokens: Int
    ) throws {
        guard let provider = resolveProvider(id: conversation.providerID) else { return }
        let cost = provider.estimatedCost(
            model: conversation.model,
            promptTokens: promptTokens,
            completionTokens: completionTokens
        )
        let assistantMessage = ChatMessage(
            role: .assistant,
            content: assistantText,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            estimatedCostUSD: cost
        )
        conversation.messages.append(assistantMessage)
        try history.save(conversation)
    }
}
