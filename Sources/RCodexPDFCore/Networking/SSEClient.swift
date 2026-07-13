import Foundation

/// A minimal Server-Sent-Events line reader built on `URLSession.bytes(for:)`.
/// Used by AI providers that stream `data: {...}` chunks (OpenAI-compatible and Anthropic-compatible APIs).
public struct SSEClient {
    public enum SSEError: Error, LocalizedError {
        case httpError(status: Int, body: String)
        case transportError(Error)

        public var errorDescription: String? {
            switch self {
            case .httpError(let status, let body):
                return "HTTP \(status): \(body)"
            case .transportError(let error):
                return error.localizedDescription
            }
        }
    }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Streams raw SSE `data:` payload lines (excluding the `data: ` prefix) as they arrive.
    /// Terminates when the server sends `[DONE]` or the stream naturally closes.
    public func stream(_ request: URLRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                        var body = ""
                        for try await line in bytes.lines { body += line }
                        continuation.finish(throwing: SSEError.httpError(status: http.statusCode, body: body))
                        return
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data:") else { continue }
                        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        if payload == "[DONE]" {
                            continuation.finish()
                            return
                        }
                        if !payload.isEmpty {
                            continuation.yield(payload)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: SSEError.transportError(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
