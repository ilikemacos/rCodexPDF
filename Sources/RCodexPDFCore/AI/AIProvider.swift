import Foundation

/// A single incremental event emitted while streaming a chat completion.
public enum AIStreamEvent: Sendable {
    case textDelta(String)
    case usage(promptTokens: Int, completionTokens: Int)
    case finished
}

public enum AIProviderError: Error, LocalizedError, Sendable {
    case missingAPIKey
    case invalidResponse(String)
    case httpError(status: Int, message: String)
    case decodingError(String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No API key configured for this provider. Add one in Preferences > AI Providers."
        case .invalidResponse(let message):
            return "Invalid response from provider: \(message)"
        case .httpError(let status, let message):
            return "Provider returned HTTP \(status): \(message)"
        case .decodingError(let message):
            return "Failed to parse provider response: \(message)"
        }
    }
}

/// Approximate USD pricing per 1M tokens, used only to show a cost estimate. `nil` means unknown.
public struct ModelPricing: Sendable {
    public let promptPerMillion: Double
    public let completionPerMillion: Double
    public init(promptPerMillion: Double, completionPerMillion: Double) {
        self.promptPerMillion = promptPerMillion
        self.completionPerMillion = completionPerMillion
    }
}

/// Common interface every AI chat provider implements. Providers perform real network calls;
/// there is no offline/mock mode. A missing or invalid API key surfaces as `AIProviderError.missingAPIKey`
/// or an HTTP error from the upstream service.
public protocol AIProvider: Sendable {
    /// Stable identifier used for Keychain storage and settings, e.g. "claude", "chatgpt".
    var id: String { get }
    var displayName: String { get }
    var availableModels: [String] { get }
    var defaultModel: String { get }

    /// Base URL, user-overridable for OpenAI-compatible community-hosted providers (Hermes, Llama).
    var defaultBaseURL: URL { get }

    func pricing(for model: String) -> ModelPricing?

    /// Streams an assistant reply for the given conversation history.
    /// `baseURLOverride` lets Hermes/Llama point at a different OpenAI-compatible host.
    func streamChat(
        messages: [ChatMessage],
        model: String,
        apiKey: String,
        baseURLOverride: URL?
    ) -> AsyncThrowingStream<AIStreamEvent, Error>
}

public extension AIProvider {
    func estimatedCost(model: String, promptTokens: Int, completionTokens: Int) -> Double? {
        guard let pricing = pricing(for: model) else { return nil }
        let promptCost = Double(promptTokens) / 1_000_000 * pricing.promptPerMillion
        let completionCost = Double(completionTokens) / 1_000_000 * pricing.completionPerMillion
        return promptCost + completionCost
    }
}
