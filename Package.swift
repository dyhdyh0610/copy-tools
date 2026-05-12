// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CopyTools",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "CopyToolsCore", targets: ["CopyToolsCore"]),
        .executable(name: "CopyTools", targets: ["CopyToolsApp"]),
        .executable(name: "CopyToolsChecks", targets: ["CopyToolsChecks"])
    ],
    targets: [
        .systemLibrary(
            name: "CSQLite"
        ),
        .target(
            name: "CopyToolsCore",
            dependencies: ["CSQLite"],
            path: "Sources/CopyToolsCore",
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .executableTarget(
            name: "CopyToolsApp",
            dependencies: ["CopyToolsCore"],
            path: "Sources/CopyToolsApp",
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        ),
        .executableTarget(
            name: "CopyToolsChecks",
            dependencies: ["CopyToolsCore"],
            path: "Tests/CopyToolsChecks"
        ),
        .testTarget(
            name: "CopyToolsCoreTests",
            dependencies: ["CopyToolsCore"],
            path: "Tests/CopyToolsCoreTests"
        )
    ]
)
