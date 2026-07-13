import Foundation

/// Google Generative Language API (`:streamGenerateContent?alt=sse`) streaming provider.
public struct GeminiProvider: AIProvider {
    public let id = "gemini"
    public let displayName = "Gemini (Google)"
    public let availableModels = [
        "gemini-2.5-pro",
        "gemini-2.5-flash",
        "gemini-2.0-flash"
    ]
    public let defaultModel = "gemini-2.5-flash"
    public let defaultBaseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta")!

    private let pricingTable: [String: ModelPricing] = [
        "gemini-2.5-pro": ModelPricing(promptPerMillion: 1.25, completionPerMillion: 10),
        "gemini-2.5-flash": ModelPricing(promptPerMillion: 0.3, completionPerMillion: 2.5),
        "gemini-2.0-flash": ModelPricing(promptPerMillion: 0.1, completionPerMillion: 0.4)
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
                    guard var components = URLComponents(
                        url: base.appendingPathComponent("models/\(model):streamGenerateContent"),
                        resolvingAgainstBaseURL: false
                    ) else { throw AIProviderError.invalidResponse("bad URL") }
                    components.queryItems = [
                        URLQueryItem(name: "alt", value: "sse"),
                        URLQueryItem(name: "key", value: apiKey)
                    ]
                    guard let url = components.url else { throw AIProviderError.invalidResponse("bad URL") }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let systemPrompt = messages.first(where: { $0.role == .system })?.content
                    let turns = messages.filter { $0.role != .system }

                    var body: [String: Any] = [
                        "contents": turns.map {
                            ["role": $0.role == .assistant ? "model" : "user",
                             "parts": [["text": $0.content]]]
                        }
                    ]
                    if let systemPrompt {
                        body["systemInstruction"] = ["parts": [["text": systemPrompt]]]
                    }
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let sse = SSEClient()
                    for try await payload in sse.stream(request) {
                        guard let data = payload.data(using: .utf8) else { continue }
                        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }

                        if let candidates = json["candidates"] as? [[String: Any]], let first = candidates.first,
                           let content = first["content"] as? [String: Any],
                           let parts = content["parts"] as? [[String: Any]] {
                            for part in parts {
                                if let text = part["text"] as? String, !text.isEmpty {
                                    continuation.yield(.textDelta(text))
                                }
                            }
                        }
                        if let usage = json["usageMetadata"] as? [String: Any] {
                            let prompt = usage["promptTokenCount"] as? Int ?? 0
                            let completion = usage["candidatesTokenCount"] as? Int ?? 0
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
