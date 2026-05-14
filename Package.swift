// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Nota",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "NotaCore", targets: ["NotaCore"]),
        .executable(name: "Nota", targets: ["NotaApp"]),
    ],
    targets: [
        .target(name: "NotaCore"),
        .executableTarget(
            name: "NotaApp",
            dependencies: ["NotaCore"]
        ),
        .testTarget(
            name: "NotaCoreTests",
            dependencies: ["NotaCore"]
        ),
        .testTarget(
            name: "NotaAppTests",
            dependencies: ["NotaApp", "NotaCore"]
        ),
    ]
)
