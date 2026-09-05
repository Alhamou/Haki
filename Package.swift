// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ArabicDictation",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ArabicDictation",
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
