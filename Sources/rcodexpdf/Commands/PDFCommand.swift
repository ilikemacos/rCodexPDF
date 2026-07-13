import ArgumentParser
import Foundation
import RCodexPDFCore

struct PDFCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pdf",
        abstract: "Open a PDF in rCodexPDF, or inspect it headlessly with flags."
    )

    @Argument(help: "Path to a .pdf file.")
    var path: String

    @Flag(name: .long, help: "Print metadata (title, author, page count) without opening the app.")
    var info = false

    @Flag(name: .long, help: "Extract and print all text content without opening the app.")
    var text = false

    @Option(name: .long, help: "Search the document and print matching pages without opening the app.")
    var search: String?

    func run() throws {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            CLIOutput.fail("File not found: \(path)")
            throw ExitCode.failure
        }

        if info || text || search != nil {
            try runHeadless(url: url)
            return
        }

        if AppLauncher.openInApp(fileURL: url) {
            CLIOutput.success("Opened \(url.lastPathComponent).")
        } else {
            CLIOutput.fail("Could not launch rCodexPDF.app.")
            throw ExitCode.failure
        }
    }

    private func runHeadless(url: URL) throws {
        let service: PDFService
        do {
            service = try PDFService(url: url)
        } catch {
            CLIOutput.fail(error.localizedDescription)
            throw ExitCode.failure
        }

        if info {
            let metadata = service.metadata()
            print(ANSI.bold("Title: ") + (metadata.title ?? "(none)"))
            print(ANSI.bold("Author: ") + (metadata.author ?? "(none)"))
            print(ANSI.bold("Pages: ") + "\(metadata.pageCount)")
            print(ANSI.bold("Encrypted: ") + "\(metadata.isEncrypted)")
            print(ANSI.bold("Size: ") + "\(metadata.fileSizeBytes) bytes")
        }

        if text {
            print(service.extractText())
        }

        if let search {
            let results = service.search(search)
            if results.isEmpty {
                CLIOutput.warn("No matches for \"\(search)\".")
            } else {
                for result in results {
                    print(ANSI.cyan("Page \(result.pageIndex + 1): ") + result.snippet)
                }
            }
        }
    }
}
