// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "rCodexPDF",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "RCodexPDFCore", targets: ["RCodexPDFCore"]),
        .executable(name: "RCodexPDF", targets: ["RCodexPDFApp"]),
        .executable(name: "rcodexpdf", targets: ["rcodexpdf"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "RCodexPDFCore",
            dependencies: [],
            path: "Sources/RCodexPDFCore"
        ),
        .executableTarget(
            name: "RCodexPDFApp",
            dependencies: ["RCodexPDFCore"],
            path: "Sources/RCodexPDFApp"
        ),
        .executableTarget(
            name: "rcodexpdf",
            dependencies: [
                "RCodexPDFCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/rcodexpdf"
        ),
        .testTarget(
            name: "RCodexPDFCoreTests",
            dependencies: ["RCodexPDFCore"],
            path: "Tests/RCodexPDFCoreTests"
        ),
        .testTarget(
            name: "CLITests",
            dependencies: [
                "rcodexpdf",
                "RCodexPDFCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Tests/CLITests"
        )
    ]
)
