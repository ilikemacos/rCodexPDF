import Foundation

public enum ChatRole: String, Codable, Sendable {
    case system
    case user
    case assistant
}

public struct ChatMessage: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var role: ChatRole
    public var content: String
    public let createdAt: Date
    public var promptTokens: Int?
    public var completionTokens: Int?
    public var estimatedCostUSD: Double?

    public init(
        id: UUID = UUID(),
        role: ChatRole,
        content: String,
        createdAt: Date = Date(),
        promptTokens: Int? = nil,
        completionTokens: Int? = nil,
        estimatedCostUSD: Double? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.estimatedCostUSD = estimatedCostUSD
    }
}

public struct Conversation: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var title: String
    public var providerID: String
    public var model: String
    public var messages: [ChatMessage]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String = "New Conversation",
        providerID: String,
        model: String,
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.providerID = providerID
        self.model = model
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Derives a short title from the first user message, matching how most chat apps label threads.
    public mutating func autoTitleIfNeeded() {
        guard title == "New Conversation", let first = messages.first(where: { $0.role == .user }) else { return }
        let trimmed = first.content.trimmingCharacters(in: .whitespacesAndNewlines)
        title = String(trimmed.prefix(60))
    }
}

public struct TotalTokenUsage: Sendable {
    public var promptTokens: Int
    public var completionTokens: Int
    public var estimatedCostUSD: Double

    public static let zero = TotalTokenUsage(promptTokens: 0, completionTokens: 0, estimatedCostUSD: 0)
}
