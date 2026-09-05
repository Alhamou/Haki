// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Haki",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Haki",
            targets: ["ArabicDictation"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ArabicDictation",
            dependencies: [],
            path: "Sources/ArabicDictation"
        ),
        .testTarget(
            name: "ArabicDictationTests",
            dependencies: ["ArabicDictation"],
            path: "Tests/ArabicDictationTests"
        )
    ]
)
