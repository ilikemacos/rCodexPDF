import Foundation

/// Runs the compile/run pipeline for a source file, streaming stdout/stderr and parsed
/// diagnostics as they arrive, and supporting cancellation via `stop()`.
public final class CompilerEngine: @unchecked Sendable {
    public static let shared = CompilerEngine()

    private var currentProcess: Process?
    private let processLock = NSLock()

    public init() {}

    private func buildDirectory(for fileURL: URL) -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("rCodexPDF-build", isDirectory: true)
            .appendingPathComponent(fileURL.deletingPathExtension().lastPathComponent, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public func run(file fileURL: URL) -> AsyncThrowingStream<BuildEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let buildDir = buildDirectory(for: fileURL)
                    let steps = try BuildPlanner.plan(for: fileURL, buildDirectory: buildDir)
                    var overallSuccess = true

                    for step in steps {
                        if Task.isCancelled { break }
                        continuation.yield(.stepStarted(step.label))
                        let exitCode = try await runStep(step, continuation: continuation)
                        continuation.yield(.processExited(step: step.label, code: exitCode))
                        if exitCode != 0 {
                            overallSuccess = false
                            break
                        }
                    }
                    continuation.yield(.finished(success: overallSuccess))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func stop() {
        processLock.lock()
        let process = currentProcess
        processLock.unlock()
        process?.terminate()
    }

    private func runStep(
        _ step: BuildStep,
        continuation: AsyncThrowingStream<BuildEvent, Error>.Continuation
    ) async throws -> Int32 {
        try await withCheckedThrowingContinuation { resume in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: step.executable)
            process.arguments = step.arguments
            process.currentDirectoryURL = step.workingDirectory

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
                for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
                    continuation.yield(.stdout(String(line)))
                }
            }
            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
                for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
                    let lineStr = String(line)
                    if let diagnostic = DiagnosticParser.parse(lineStr) {
                        continuation.yield(.diagnostic(diagnostic))
                    }
                    continuation.yield(.stderr(lineStr))
                }
            }

            process.terminationHandler = { proc in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                self.processLock.lock()
                self.currentProcess = nil
                self.processLock.unlock()
                resume.resume(returning: proc.terminationStatus)
            }

            do {
                processLock.lock()
                currentProcess = process
                processLock.unlock()
                try process.run()
            } catch {
                processLock.lock()
                currentProcess = nil
                processLock.unlock()
                resume.resume(throwing: error)
            }
        }
    }
}
