import XCTest
@testable import RCodexPDFCore

final class ChatHistoryStoreTests: XCTestCase {
    private func makeIsolatedStore() -> (ChatHistoryStore, URL) {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return (ChatHistoryStore(directory: dir), dir)
    }

    func testSaveAndLoad() throws {
        let (store, dir) = makeIsolatedStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        var conversation = Conversation(providerID: "claude", model: "claude-sonnet-5")
        conversation.messages.append(ChatMessage(role: .user, content: "Hello there"))
        try store.save(conversation)

        let loaded = store.load(conversation.id)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.messages.first?.content, "Hello there")
        XCTAssertEqual(loaded?.title, "Hello there") // auto-titled from first user message
    }

    func testSearchMatchesTitleAndBody() throws {
        let (store, dir) = makeIsolatedStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        var a = Conversation(providerID: "claude", model: "m")
        a.messages.append(ChatMessage(role: .user, content: "Tell me about pandas"))
        var b = Conversation(providerID: "chatgpt", model: "m")
        b.messages.append(ChatMessage(role: .user, content: "Tell me about rockets"))
        try store.save(a)
        try store.save(b)

        let results = store.search("pandas")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, a.id)
    }

    func testDelete() throws {
        let (store, dir) = makeIsolatedStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        let conversation = Conversation(providerID: "claude", model: "m")
        try store.save(conversation)
        XCTAssertNotNil(store.load(conversation.id))

        try store.delete(conversation.id)
        XCTAssertNil(store.load(conversation.id))
    }

    func testExportMarkdownContainsMessages() throws {
        let (store, dir) = makeIsolatedStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        var conversation = Conversation(providerID: "claude", model: "m")
        conversation.messages.append(ChatMessage(role: .user, content: "What is 2+2?"))
        conversation.messages.append(ChatMessage(role: .assistant, content: "4"))

        let exportURL = dir.appendingPathComponent("export.md")
        try store.exportMarkdown(conversation, to: exportURL)

        let text = try String(contentsOf: exportURL, encoding: .utf8)
        XCTAssertTrue(text.contains("What is 2+2?"))
        XCTAssertTrue(text.contains("4"))
    }

    func testTotalUsageSumsAcrossConversations() throws {
        let (store, dir) = makeIsolatedStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        var a = Conversation(providerID: "claude", model: "m")
        a.messages.append(ChatMessage(role: .assistant, content: "hi", promptTokens: 10, completionTokens: 5, estimatedCostUSD: 0.01))
        var b = Conversation(providerID: "chatgpt", model: "m")
        b.messages.append(ChatMessage(role: .assistant, content: "hi", promptTokens: 20, completionTokens: 15, estimatedCostUSD: 0.02))
        try store.save(a)
        try store.save(b)

        let total = store.totalUsage()
        XCTAssertEqual(total.promptTokens, 30)
        XCTAssertEqual(total.completionTokens, 20)
        XCTAssertEqual(total.estimatedCostUSD, 0.03, accuracy: 0.0001)
    }
}
