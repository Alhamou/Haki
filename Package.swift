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
            targets: ["Haki"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Haki",
            dependencies: [],
            path: "Sources/Haki"
        ),
        .testTarget(
            name: "HakiTests",
            dependencies: ["Haki"],
            path: "Tests/HakiTests"
        )
    ]
)
