// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Tabula",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "tabula", targets: ["TabulaCLI"]),
        .executable(name: "TabulaApp", targets: ["TabulaApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", .upToNextMinor(from: "0.9.0")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.8.2"),
    ],
    targets: [
        .target(name: "TabulaCore", dependencies: [.product(name: "Markdown", package: "swift-markdown")]),
        .executableTarget(name: "TabulaCLI", dependencies: ["TabulaCore", .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .executableTarget(name: "TabulaApp", dependencies: ["TabulaCore"], swiftSettings: [.defaultIsolation(MainActor.self)]),
        .testTarget(name: "TabulaCoreTests", dependencies: ["TabulaCore"]),
    ]
)
