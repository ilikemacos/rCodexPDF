import Foundation

/// Central registry of all supported AI providers. Each entry is a real network client;
/// `baseURLOverride` (persisted per-provider in AppSettings) lets Hermes and Llama point at
/// whichever OpenAI-compatible host the user has a key for.
public enum AIProviderRegistry {
    public static let chatgpt = OpenAICompatibleProvider(
        id: "chatgpt",
        displayName: "ChatGPT (OpenAI)",
        availableModels: ["gpt-5", "gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"],
        defaultModel: "gpt-4o",
        defaultBaseURL: URL(string: "https://api.openai.com/v1")!,
        pricingTable: [
            "gpt-4o": ModelPricing(promptPerMillion: 2.5, completionPerMillion: 10),
            "gpt-4o-mini": ModelPricing(promptPerMillion: 0.15, completionPerMillion: 0.6),
            "gpt-4-turbo": ModelPricing(promptPerMillion: 10, completionPerMillion: 30),
            "gpt-3.5-turbo": ModelPricing(promptPerMillion: 0.5, completionPerMillion: 1.5)
        ]
    )

    public static let openRouter = OpenAICompatibleProvider(
        id: "openrouter",
        displayName: "OpenRouter",
        availableModels: [
            "openrouter/auto",
            "anthropic/claude-sonnet-4.5",
            "openai/gpt-4o",
            "meta-llama/llama-3.1-405b-instruct",
            "nousresearch/hermes-3-llama-3.1-405b"
        ],
        defaultModel: "openrouter/auto",
        defaultBaseURL: URL(string: "https://openrouter.ai/api/v1")!,
        pricingTable: [:],
        extraHeaders: [
            "HTTP-Referer": "https://github.com/ilikemacos/rCodexPDF",
            "X-Title": "rCodexPDF"
        ]
    )

    public static let grok = OpenAICompatibleProvider(
        id: "grok",
        displayName: "Grok (xAI)",
        availableModels: ["grok-4", "grok-3", "grok-3-mini"],
        defaultModel: "grok-4",
        defaultBaseURL: URL(string: "https://api.x.ai/v1")!,
        pricingTable: [
            "grok-4": ModelPricing(promptPerMillion: 3, completionPerMillion: 15),
            "grok-3": ModelPricing(promptPerMillion: 3, completionPerMillion: 15),
            "grok-3-mini": ModelPricing(promptPerMillion: 0.3, completionPerMillion: 0.5)
        ]
    )

    /// Nous Research's Hermes models. No single official hosted API exists, so this defaults to
    /// OpenRouter's Hermes routing; users can override the base URL in Preferences to point at
    /// any other OpenAI-compatible Hermes host.
    public static let hermes = OpenAICompatibleProvider(
        id: "hermes",
        displayName: "Hermes (Nous Research)",
        availableModels: [
            "nousresearch/hermes-3-llama-3.1-405b",
            "nousresearch/hermes-3-llama-3.1-70b"
        ],
        defaultModel: "nousresearch/hermes-3-llama-3.1-405b",
        defaultBaseURL: URL(string: "https://openrouter.ai/api/v1")!
    )

    /// Meta's Llama models. Defaults to Groq's OpenAI-compatible endpoint (free-tier friendly,
    /// directly hosts Llama); users can override the base URL to any other OpenAI-compatible host.
    public static let llama = OpenAICompatibleProvider(
        id: "llama",
        displayName: "Llama (Meta)",
        availableModels: ["llama-3.3-70b-versatile", "llama-3.1-8b-instant"],
        defaultModel: "llama-3.3-70b-versatile",
        defaultBaseURL: URL(string: "https://api.groq.com/openai/v1")!
    )

    public static let claude = ClaudeProvider()
    public static let gemini = GeminiProvider()

    public static let all: [any AIProvider] = [claude, chatgpt, gemini, openRouter, grok, hermes, llama]

    public static func provider(withID id: String) -> (any AIProvider)? {
        all.first { $0.id == id }
    }
}
