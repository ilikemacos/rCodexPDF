import Foundation

/// Persists chat conversations as one JSON file per conversation under
/// `~/Library/Application Support/rCodexPDF/ChatHistory/`, and supports
/// search, export (single-file JSON or Markdown), and import.
public final class ChatHistoryStore: @unchecked Sendable {
    public static let shared = ChatHistoryStore()

    private let directory: URL
    private let lock = NSLock()

    public init(directory: URL = ApplicationSupport.chatHistoryDirectory) {
        self.directory = directory
    }

    private func fileURL(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).json")
    }

    public func save(_ conversation: Conversation) throws {
        lock.lock(); defer { lock.unlock() }
        var conv = conversation
        conv.updatedAt = Date()
        conv.autoTitleIfNeeded()
        try JSONFileStore.save(conv, to: fileURL(for: conv.id))
    }

    public func delete(_ id: UUID) throws {
        lock.lock(); defer { lock.unlock() }
        let url = fileURL(for: id)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    public func loadAll() -> [Conversation] {
        lock.lock(); defer { lock.unlock() }
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        ) else { return [] }
        let conversations = files
            .filter { $0.pathExtension == "json" }
            .compactMap { JSONFileStore.load(Conversation.self, from: $0) }
        return conversations.sorted { $0.updatedAt > $1.updatedAt }
    }

    public func load(_ id: UUID) -> Conversation? {
        lock.lock(); defer { lock.unlock() }
        return JSONFileStore.load(Conversation.self, from: fileURL(for: id))
    }

    /// Case-insensitive full-text search across conversation titles and message contents.
    public func search(_ query: String) -> [Conversation] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return loadAll() }
        let needle = query.lowercased()
        return loadAll().filter { conversation in
            if conversation.title.lowercased().contains(needle) { return true }
            return conversation.messages.contains { $0.content.lowercased().contains(needle) }
        }
    }

    // MARK: - Export / Import

    public func exportJSON(_ conversation: Conversation, to url: URL) throws {
        try JSONFileStore.save(conversation, to: url)
    }

    public func exportMarkdown(_ conversation: Conversation, to url: URL) throws {
        var markdown = "# \(conversation.title)\n\n"
        markdown += "- Provider: \(conversation.providerID)\n- Model: \(conversation.model)\n- Created: \(conversation.createdAt)\n\n---\n\n"
        for message in conversation.messages {
            let speaker = message.role == .user ? "**You**" : (message.role == .assistant ? "**Assistant**" : "**System**")
            markdown += "\(speaker):\n\n\(message.content)\n\n---\n\n"
        }
        try markdown.write(to: url, atomically: true, encoding: .utf8)
    }

    public func importJSON(from url: URL) throws -> Conversation {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var conversation = try decoder.decode(Conversation.self, from: data)
        // Assign a fresh ID on import to avoid clobbering an existing conversation with the same ID.
        conversation = Conversation(
            id: UUID(),
            title: conversation.title,
            providerID: conversation.providerID,
            model: conversation.model,
            messages: conversation.messages,
            createdAt: conversation.createdAt,
            updatedAt: Date()
        )
        try save(conversation)
        return conversation
    }

    public func totalUsage() -> TotalTokenUsage {
        var total = TotalTokenUsage.zero
        for conversation in loadAll() {
            for message in conversation.messages {
                total.promptTokens += message.promptTokens ?? 0
                total.completionTokens += message.completionTokens ?? 0
                total.estimatedCostUSD += message.estimatedCostUSD ?? 0
            }
        }
        return total
    }
}
