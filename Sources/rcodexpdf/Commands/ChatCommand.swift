import ArgumentParser
import Foundation
import RCodexPDFCore

struct ChatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "chat",
        abstract: "Start an interactive AI chat session in the terminal."
    )

    @Option(name: .long, help: "Provider id (claude, chatgpt, gemini, openrouter, grok, hermes, llama). Defaults to the last-used provider.")
    var provider: String?

    @Option(name: .long, help: "Model to use. Defaults to the provider's default model.")
    var model: String?

    @Argument(help: "Optional single message to send non-interactively; prints the reply and exits.")
    var message: [String] = []

    func run() async throws {
        let settings = AppSettings.shared
        let keychain = KeychainStore()
        let controller = ChatController()

        let providerID = provider ?? settings.defaultAIProvider
        guard let aiProvider = AIProviderRegistry.provider(withID: providerID) else {
            CLIOutput.fail("Unknown provider '\(providerID)'. Available: \(AIProviderRegistry.all.map(\.id).joined(separator: ", "))")
            throw ExitCode.failure
        }
        guard keychain.hasAPIKey(for: providerID) else {
            CLIOutput.fail("No API key set for \(aiProvider.displayName). Run `rcodexpdf config set-key \(providerID)` first.")
            throw ExitCode.failure
        }
        let selectedModel = model ?? settings.selectedModel(forProvider: providerID) ?? aiProvider.defaultModel

        var conversation = Conversation(providerID: providerID, model: selectedModel)

        if !message.isEmpty {
            try await sendAndPrint(message.joined(separator: " "), conversation: &conversation, controller: controller)
            return
        }

        CLIOutput.info("Chatting with \(ANSI.bold(aiProvider.displayName)) (\(selectedModel)). Type /exit to quit, /new for a new conversation.")
        while true {
            print(ANSI.green("you> "), terminator: "")
            guard let line = readLine() else { break }
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            if trimmed == "/exit" || trimmed == "/quit" { break }
            if trimmed == "/new" {
                conversation = Conversation(providerID: providerID, model: selectedModel)
                CLIOutput.info("Started a new conversation.")
                continue
            }
            do {
                try await sendAndPrint(trimmed, conversation: &conversation, controller: controller)
            } catch {
                CLIOutput.fail(error.localizedDescription)
            }
        }
    }

    private func sendAndPrint(_ text: String, conversation: inout Conversation, controller: ChatController) async throws {
        let stream = try controller.send(userText: text, in: &conversation)
        print(ANSI.blue("assistant> "), terminator: "")
        var fullText = ""
        var promptTokens = 0
        var completionTokens = 0
        for try await event in stream {
            switch event {
            case .textDelta(let delta):
                fullText += delta
                print(delta, terminator: "")
                fflush(stdout)
            case .usage(let prompt, let completion):
                promptTokens += prompt
                completionTokens += completion
            case .finished:
                break
            }
        }
        print("")
        try controller.finish(conversation: &conversation, assistantText: fullText, promptTokens: promptTokens, completionTokens: completionTokens)
    }
}
