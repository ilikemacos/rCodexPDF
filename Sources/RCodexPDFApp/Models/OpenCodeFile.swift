import Foundation
import Combine
import RCodexPDFCore

@MainActor
final class OpenCodeFile: ObservableObject, Identifiable {
    let id = UUID()
    @Published var url: URL?
    @Published var title: String
    @Published var content: String
    @Published var isDirty = false
    @Published var language: ProgrammingLanguage?

    @Published var outputLines: [OutputLine] = []
    @Published var diagnostics: [CompilerDiagnostic] = []
    @Published var isRunning = false

    struct OutputLine: Identifiable {
        let id = UUID()
        let text: String
        let isError: Bool
    }

    private let engine = CompilerEngine.shared
    private var autoSaveTimer: Timer?
    private let settings = AppSettings.shared
    private var runTask: Task<Void, Never>?

    init(url: URL?) {
        self.url = url
        if let url {
            self.title = url.lastPathComponent
            self.content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            self.language = ProgrammingLanguage.detect(from: url)
        } else {
            self.title = "Untitled"
            self.content = ""
            self.language = nil
        }
        scheduleAutoSaveIfNeeded()
    }

    func markDirty() {
        isDirty = true
        scheduleAutoSaveIfNeeded()
    }

    private func scheduleAutoSaveIfNeeded() {
        guard settings.autoSaveEnabled, url != nil else { return }
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.save() }
        }
    }

    func save() {
        guard let url else { return }
        try? content.write(to: url, atomically: true, encoding: .utf8)
        isDirty = false
    }

    func saveAs(url: URL) {
        self.url = url
        self.title = url.lastPathComponent
        self.language = ProgrammingLanguage.detect(from: url)
        save()
    }

    func run() {
        guard let url, !isRunning else { return }
        if isDirty { save() }
        outputLines.removeAll()
        diagnostics.removeAll()
        isRunning = true

        runTask = Task {
            do {
                for try await event in engine.run(file: url) {
                    await MainActor.run {
                        switch event {
                        case .stdout(let line):
                            outputLines.append(OutputLine(text: line, isError: false))
                        case .stderr(let line):
                            outputLines.append(OutputLine(text: line, isError: true))
                        case .diagnostic(let diagnostic):
                            diagnostics.append(diagnostic)
                        case .stepStarted(let label):
                            outputLines.append(OutputLine(text: "▶ \(label)…", isError: false))
                        case .processExited(let step, let code):
                            outputLines.append(OutputLine(text: "\(step) exited with code \(code)", isError: code != 0))
                        case .finished:
                            break
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    outputLines.append(OutputLine(text: error.localizedDescription, isError: true))
                }
            }
            await MainActor.run { isRunning = false }
        }
    }

    func stop() {
        engine.stop()
        runTask?.cancel()
        isRunning = false
    }

    func format() {
        guard let url, let language else { return }
        if isDirty { save() }
        do {
            try CodeFormatter.format(file: url, language: language)
            content = (try? String(contentsOf: url, encoding: .utf8)) ?? content
        } catch {
            outputLines.append(OutputLine(text: error.localizedDescription, isError: true))
        }
    }
}
