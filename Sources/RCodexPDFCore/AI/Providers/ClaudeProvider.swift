import Foundation

/// Anthropic Messages API (`/v1/messages`, `anthropic-version: 2023-06-01`) streaming provider.
public struct ClaudeProvider: AIProvider {
    public let id = "claude"
    public let displayName = "Claude (Anthropic)"
    public let availableModels = [
        "claude-opus-4-8",
        "claude-sonnet-5",
        "claude-haiku-4-5-20251001"
    ]
    public let defaultModel = "claude-sonnet-5"
    public let defaultBaseURL = URL(string: "https://api.anthropic.com/v1")!

    private let pricingTable: [String: ModelPricing] = [
        "claude-opus-4-8": ModelPricing(promptPerMillion: 15, completionPerMillion: 75),
        "claude-sonnet-5": ModelPricing(promptPerMillion: 3, completionPerMillion: 15),
        "claude-haiku-4-5-20251001": ModelPricing(promptPerMillion: 0.8, completionPerMillion: 4)
    ]

    public init() {}

    public func pricing(for model: String) -> ModelPricing? { pricingTable[model] }

    public func streamChat(
        messages: [ChatMessage],
        model: String,
        apiKey: String,
        baseURLOverride: URL?
    ) -> AsyncThrowingStream<AIStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard !apiKey.isEmpty else { throw AIProviderError.missingAPIKey }
                    let base = baseURLOverride ?? defaultBaseURL
                    let url = base.appendingPathComponent("messages")

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

                    let systemPrompt = messages.first(where: { $0.role == .system })?.content
                    let turns = messages.filter { $0.role != .system }

                    var body: [String: Any] = [
                        "model": model,
                        "max_tokens": 4096,
                        "stream": true,
                        "messages": turns.map { ["role": $0.role.rawValue, "content": $0.content] }
                    ]
                    if let systemPrompt { body["system"] = systemPrompt }
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let sse = SSEClient()
                    for try await payload in sse.stream(request) {
                        guard let data = payload.data(using: .utf8) else { continue }
                        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
                        guard let type = json["type"] as? String else { continue }

                        switch type {
                        case "content_block_delta":
                            if let delta = json["delta"] as? [String: Any], let text = delta["text"] as? String {
                                continuation.yield(.textDelta(text))
                            }
                        case "message_start":
                            if let message = json["message"] as? [String: Any],
                               let usage = message["usage"] as? [String: Any],
                               let input = usage["input_tokens"] as? Int {
                                continuation.yield(.usage(promptTokens: input, completionTokens: 0))
                            }
                        case "message_delta":
                            if let usage = json["usage"] as? [String: Any],
                               let output = usage["output_tokens"] as? Int {
                                continuation.yield(.usage(promptTokens: 0, completionTokens: output))
                            }
                        default:
                            break
                        }
                    }
                    continuation.yield(.finished)
                    continuation.finish()
                } catch let error as SSEClient.SSEError {
                    if case .httpError(let status, let message) = error {
                        continuation.finish(throwing: AIProviderError.httpError(status: status, message: message))
                    } else {
                        continuation.finish(throwing: error)
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
