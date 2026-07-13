import XCTest
@testable import RCodexPDFCore

final class ProgrammingLanguageTests: XCTestCase {
    func testDetectFromExtension() {
        XCTAssertEqual(ProgrammingLanguage.detect(from: URL(fileURLWithPath: "main.cpp")), .cpp)
        XCTAssertEqual(ProgrammingLanguage.detect(from: URL(fileURLWithPath: "script.py")), .python)
        XCTAssertEqual(ProgrammingLanguage.detect(from: URL(fileURLWithPath: "app.tsx")), nil)
        XCTAssertEqual(ProgrammingLanguage.detect(from: URL(fileURLWithPath: "Program.cs")), .csharp)
        XCTAssertEqual(ProgrammingLanguage.detect(from: URL(fileURLWithPath: "run.sh")), .bash)
    }

    func testLuaIsNotSupported() {
        XCTAssertNil(ProgrammingLanguage.detect(from: URL(fileURLWithPath: "script.lua")))
        for language in ProgrammingLanguage.allCases {
            XCTAssertNotEqual(language.displayName.lowercased(), "lua")
        }
    }

    func testAllCasesHaveNonEmptyExtensions() {
        for language in ProgrammingLanguage.allCases {
            XCTAssertFalse(language.fileExtensions.isEmpty, "\(language) has no extensions")
        }
    }
}

final class DiagnosticParserTests: XCTestCase {
    func testParsesClangStyleDiagnostic() {
        let line = "main.c:12:5: error: expected ';' after expression"
        let diagnostic = DiagnosticParser.parse(line)
        XCTAssertNotNil(diagnostic)
        XCTAssertEqual(diagnostic?.file, "main.c")
        XCTAssertEqual(diagnostic?.line, 12)
        XCTAssertEqual(diagnostic?.column, 5)
        XCTAssertEqual(diagnostic?.severity, .error)
    }

    func testParsesJavacStyleDiagnostic() {
        let line = "Main.java:8: error: cannot find symbol"
        let diagnostic = DiagnosticParser.parse(line)
        XCTAssertNotNil(diagnostic)
        XCTAssertEqual(diagnostic?.file, "Main.java")
        XCTAssertEqual(diagnostic?.line, 8)
        XCTAssertNil(diagnostic?.column)
    }

    func testParsesTscStyleDiagnostic() {
        let line = "app.ts(10,3): error TS2322: Type 'string' is not assignable to type 'number'."
        let diagnostic = DiagnosticParser.parse(line)
        XCTAssertNotNil(diagnostic)
        XCTAssertEqual(diagnostic?.file, "app.ts")
        XCTAssertEqual(diagnostic?.line, 10)
        XCTAssertEqual(diagnostic?.column, 3)
    }

    func testIgnoresNonDiagnosticLines() {
        XCTAssertNil(DiagnosticParser.parse("Hello, world!"))
        XCTAssertNil(DiagnosticParser.parse(""))
    }
}

final class BuildPlannerTests: XCTestCase {
    func testUnsupportedExtensionThrows() {
        let file = URL(fileURLWithPath: "/tmp/script.lua")
        XCTAssertThrowsError(try BuildPlanner.plan(for: file, buildDirectory: FileManager.default.temporaryDirectory)) { error in
            guard case CompilerError.unsupportedLanguage(let ext) = error else {
                XCTFail("Expected unsupportedLanguage, got \(error)")
                return
            }
            XCTAssertEqual(ext, "lua")
        }
    }

    func testMissingToolchainThrowsWithClearMessage() {
        // A made-up extension that maps to a language whose toolchain is extremely unlikely
        // to be present in a minimal CI runner: Kotlin.
        let file = URL(fileURLWithPath: "/tmp/Program.kt")
        do {
            _ = try BuildPlanner.plan(for: file, buildDirectory: FileManager.default.temporaryDirectory)
            // If kotlinc happens to be installed on the machine running this test, that's fine too.
        } catch CompilerError.toolchainNotFound(let tool, let language) {
            XCTAssertEqual(tool, "kotlinc")
            XCTAssertEqual(language, "Kotlin")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
