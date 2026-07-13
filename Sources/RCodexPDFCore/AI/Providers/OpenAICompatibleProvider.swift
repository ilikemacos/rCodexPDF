import Foundation

/// Implements any provider exposing an OpenAI-compatible `POST /chat/completions` streaming
/// endpoint: OpenAI (ChatGPT), OpenRouter, xAI (Grok), and OpenAI-compatible community hosts
/// used for Hermes and Llama models (default hosts are overridable via Settings).
public struct OpenAICompatibleProvider: AIProvider {
    public let id: String
    public let displayName: String
    public let availableModels: [String]
    public let defaultModel: String
    public let defaultBaseURL: URL
    private let pricingTable: [String: ModelPricing]
    private let extraHeaders: [String: String]

    public init(
        id: String,
        displayName: String,
        availableModels: [String],
        defaultModel: String,
        defaultBaseURL: URL,
        pricingTable: [String: ModelPricing] = [:],
        extraHeaders: [String: String] = [:]
    ) {
        self.id = id
        self.displayName = displayName
        self.availableModels = availableModels
        self.defaultModel = defaultModel
        self.defaultBaseURL = defaultBaseURL
        self.pricingTable = pricingTable
        self.extraHeaders = extraHeaders
    }

    public func pricing(for model: String) -> ModelPricing? {
        pricingTable[model]
    }

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
                    let url = base.appendingPathComponent("chat/completions")

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    for (key, value) in extraHeaders {
                        request.setValue(value, forHTTPHeaderField: key)
                    }

                    let body: [String: Any] = [
                        "model": model,
                        "stream": true,
                        "stream_options": ["include_usage": true],
                        "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] }
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let sse = SSEClient()
                    for try await payload in sse.stream(request) {
                        guard let data = payload.data(using: .utf8) else { continue }
                        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }

                        if let choices = json["choices"] as? [[String: Any]], let first = choices.first {
                            if let delta = first["delta"] as? [String: Any], let content = delta["content"] as? String, !content.isEmpty {
                                continuation.yield(.textDelta(content))
                            }
                        }
                        if let usage = json["usage"] as? [String: Any] {
                            let prompt = usage["prompt_tokens"] as? Int ?? 0
                            let completion = usage["completion_tokens"] as? Int ?? 0
                            if prompt > 0 || completion > 0 {
                                continuation.yield(.usage(promptTokens: prompt, completionTokens: completion))
                            }
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
