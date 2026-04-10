// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyFinder",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "KeyFinder",
            targets: ["KeyFinder"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "KeyFinder",
            dependencies: [],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "KeyFinderTests",
            dependencies: ["KeyFinder"]
        )
    ]
)
