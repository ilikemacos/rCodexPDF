import Foundation

/// Builds the sequence of `BuildStep`s (compile, then run) for a source file, based on which
/// toolchains are actually present on this machine. Throws `CompilerError.toolchainNotFound`
/// immediately if a required tool is missing, rather than silently no-opping.
public enum BuildPlanner {
    public static func plan(for fileURL: URL, buildDirectory: URL) throws -> [BuildStep] {
        guard let language = ProgrammingLanguage.detect(from: fileURL) else {
            throw CompilerError.unsupportedLanguage(fileURL.pathExtension)
        }
        let dir = fileURL.deletingLastPathComponent()
        let name = fileURL.deletingPathExtension().lastPathComponent
        let outputBinary = buildDirectory.appendingPathComponent(name).path

        func require(_ tool: String) throws -> String {
            guard let path = ToolchainLocator.find(tool) else {
                throw CompilerError.toolchainNotFound(tool: tool, language: language.displayName)
            }
            return path
        }

        switch language {
        case .c:
            let clang = try require("clang")
            return [
                BuildStep(label: "Compile", executable: clang, arguments: [fileURL.path, "-o", outputBinary], workingDirectory: dir),
                BuildStep(label: "Run", executable: outputBinary, arguments: [], workingDirectory: dir)
            ]
        case .cpp:
            let clangpp = try require("clang++")
            return [
                BuildStep(label: "Compile", executable: clangpp, arguments: ["-std=c++17", fileURL.path, "-o", outputBinary], workingDirectory: dir),
                BuildStep(label: "Run", executable: outputBinary, arguments: [], workingDirectory: dir)
            ]
        case .rust:
            let rustc = try require("rustc")
            return [
                BuildStep(label: "Compile", executable: rustc, arguments: [fileURL.path, "-o", outputBinary], workingDirectory: dir),
                BuildStep(label: "Run", executable: outputBinary, arguments: [], workingDirectory: dir)
            ]
        case .go:
            let go = try require("go")
            return [
                BuildStep(label: "Run", executable: go, arguments: ["run", fileURL.path], workingDirectory: dir)
            ]
        case .python:
            let python3 = try ToolchainLocator.find("python3") ?? require("python")
            return [
                BuildStep(label: "Run", executable: python3, arguments: ["-u", fileURL.path], workingDirectory: dir)
            ]
        case .java:
            let javac = try require("javac")
            let java = try require("java")
            return [
                BuildStep(label: "Compile", executable: javac, arguments: ["-d", buildDirectory.path, fileURL.path], workingDirectory: dir),
                BuildStep(label: "Run", executable: java, arguments: ["-cp", buildDirectory.path, name], workingDirectory: dir)
            ]
        case .javascript:
            let node = try require("node")
            return [
                BuildStep(label: "Run", executable: node, arguments: [fileURL.path], workingDirectory: dir)
            ]
        case .typescript:
            let node = try require("node")
            if let tsNode = ToolchainLocator.find("ts-node") {
                return [BuildStep(label: "Run", executable: tsNode, arguments: [fileURL.path], workingDirectory: dir)]
            }
            let tsc = try require("tsc")
            let outFile = buildDirectory.appendingPathComponent("\(name).js").path
            return [
                BuildStep(label: "Compile", executable: tsc, arguments: [fileURL.path, "--outFile", outFile, "--target", "ES2020", "--module", "commonjs"], workingDirectory: dir),
                BuildStep(label: "Run", executable: node, arguments: [outFile], workingDirectory: dir)
            ]
        case .swift:
            let swift = try require("swift")
            return [
                BuildStep(label: "Run", executable: swift, arguments: [fileURL.path], workingDirectory: dir)
            ]
        case .kotlin:
            let kotlinc = try require("kotlinc")
            let java = try require("java")
            let jarPath = buildDirectory.appendingPathComponent("\(name).jar").path
            return [
                BuildStep(label: "Compile", executable: kotlinc, arguments: [fileURL.path, "-include-runtime", "-d", jarPath], workingDirectory: dir),
                BuildStep(label: "Run", executable: java, arguments: ["-jar", jarPath], workingDirectory: dir)
            ]
        case .csharp:
            let dotnet = try require("dotnet")
            // Modern .NET SDKs (9+) support running a single C# file directly.
            return [
                BuildStep(label: "Run", executable: dotnet, arguments: ["run", fileURL.path], workingDirectory: dir)
            ]
        case .php:
            let php = try require("php")
            return [
                BuildStep(label: "Run", executable: php, arguments: [fileURL.path], workingDirectory: dir)
            ]
        case .ruby:
            let ruby = try require("ruby")
            return [
                BuildStep(label: "Run", executable: ruby, arguments: [fileURL.path], workingDirectory: dir)
            ]
        case .bash:
            let bash = try require("bash")
            return [
                BuildStep(label: "Run", executable: bash, arguments: [fileURL.path], workingDirectory: dir)
            ]
        }
    }
}
