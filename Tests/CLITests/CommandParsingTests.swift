import XCTest
import ArgumentParser
import RCodexPDFCore
@testable import rcodexpdf

final class CommandParsingTests: XCTestCase {
    func testOpenCommandParsesPath() throws {
        let command = try OpenCommand.parse(["document.pdf"])
        XCTAssertEqual(command.path, "document.pdf")
    }

    func testPDFCommandDefaultsToOpening() throws {
        let command = try PDFCommand.parse(["report.pdf"])
        XCTAssertEqual(command.path, "report.pdf")
        XCTAssertFalse(command.info)
        XCTAssertFalse(command.text)
        XCTAssertNil(command.search)
    }

    func testPDFCommandParsesHeadlessFlags() throws {
        let command = try PDFCommand.parse(["report.pdf", "--info", "--search", "invoice"])
        XCTAssertTrue(command.info)
        XCTAssertEqual(command.search, "invoice")
    }

    func testCompileCommandParsesPath() throws {
        let command = try CompileCommand.parse(["main.cpp"])
        XCTAssertEqual(command.path, "main.cpp")
    }

    func testChatCommandParsesProviderAndModel() throws {
        let command = try ChatCommand.parse(["--provider", "chatgpt", "--model", "gpt-4o"])
        XCTAssertEqual(command.provider, "chatgpt")
        XCTAssertEqual(command.model, "gpt-4o")
        XCTAssertTrue(command.message.isEmpty)
    }

    func testChatCommandParsesInlineMessage() throws {
        let command = try ChatCommand.parse(["explain", "this", "code"])
        XCTAssertEqual(command.message, ["explain", "this", "code"])
    }

    func testConfigSetParsesKeyAndValue() throws {
        let command = try ConfigSet.parse(["auto-save", "false"])
        XCTAssertEqual(command.key, "auto-save")
        XCTAssertEqual(command.value, "false")
    }

    func testConfigSetRejectsInvalidBoolean() throws {
        var command = try ConfigSet.parse(["auto-save", "not-a-bool"])
        XCTAssertThrowsError(try command.run())
    }

    func testConfigGetRejectsUnknownKey() throws {
        var command = try ConfigGet.parse(["nonexistent-key"])
        XCTAssertThrowsError(try command.run())
    }

    func testUninstallDefaultsAreSafe() throws {
        let command = try UninstallCommand.parse([])
        XCTAssertFalse(command.purge)
        XCTAssertFalse(command.yes)
    }

    func testRootCommandHasAllSubcommands() {
        let subcommandNames = Set(RCodexPDFCLI.configuration.subcommands.map { $0.configuration.commandName ?? "" })
        XCTAssertEqual(subcommandNames, ["open", "pdf", "compile", "chat", "config", "update", "uninstall"])
    }

    func testVersionMatchesConfiguration() {
        XCTAssertEqual(RCodexPDFVersion.current, RCodexPDFCLI.configuration.version)
    }
}
