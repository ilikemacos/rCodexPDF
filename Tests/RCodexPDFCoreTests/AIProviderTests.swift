import XCTest
@testable import RCodexPDFCore

final class AIProviderRegistryTests: XCTestCase {
    func testAllSevenProvidersRegistered() {
        let ids = Set(AIProviderRegistry.all.map(\.id))
        XCTAssertEqual(ids, ["claude", "chatgpt", "gemini", "openrouter", "grok", "hermes", "llama"])
    }

    func testLookupByID() {
        XCTAssertEqual(AIProviderRegistry.provider(withID: "claude")?.displayName, "Claude (Anthropic)")
        XCTAssertNil(AIProviderRegistry.provider(withID: "does-not-exist"))
    }

    func testEveryProviderHasADefaultModelInItsOwnList() {
        for provider in AIProviderRegistry.all {
            XCTAssertTrue(
                provider.availableModels.contains(provider.defaultModel),
                "\(provider.id)'s defaultModel '\(provider.defaultModel)' is not in its own availableModels list"
            )
        }
    }

    func testCostEstimation() {
        let provider = AIProviderRegistry.chatgpt
        let cost = provider.estimatedCost(model: "gpt-4o-mini", promptTokens: 1_000_000, completionTokens: 1_000_000)
        XCTAssertEqual(cost, 0.15 + 0.6, accuracy: 0.0001)
    }

    func testUnknownModelHasNoCostEstimate() {
        let provider = AIProviderRegistry.hermes
        XCTAssertNil(provider.pricing(for: "totally-unknown-model"))
    }

    func testMissingAPIKeyThrowsBeforeAnyNetworkCall() async throws {
        let provider = AIProviderRegistry.claude
        let stream = provider.streamChat(messages: [], model: provider.defaultModel, apiKey: "", baseURLOverride: nil)
        var caught: Error?
        do {
            for try await _ in stream { XCTFail("Should not yield any events") }
        } catch {
            caught = error
        }
        XCTAssertTrue(caught is AIProviderError)
        if case .missingAPIKey = caught as? AIProviderError {
            // expected
        } else {
            XCTFail("Expected missingAPIKey, got \(String(describing: caught))")
        }
    }
}

final class KeychainStoreTests: XCTestCase {
    func testSetGetDeleteRoundTrip() throws {
        let store = KeychainStore()
        let providerID = "test-provider-\(UUID().uuidString)"
        defer { store.deleteAPIKey(for: providerID) }

        XCTAssertNil(store.getAPIKey(for: providerID))
        try store.setAPIKey("sk-test-12345", for: providerID)
        XCTAssertEqual(store.getAPIKey(for: providerID), "sk-test-12345")
        XCTAssertTrue(store.hasAPIKey(for: providerID))

        try store.setAPIKey("sk-test-updated", for: providerID)
        XCTAssertEqual(store.getAPIKey(for: providerID), "sk-test-updated")

        XCTAssertTrue(store.deleteAPIKey(for: providerID))
        XCTAssertNil(store.getAPIKey(for: providerID))
    }
}
