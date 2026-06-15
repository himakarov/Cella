// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Cella",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Cella",
            path: "Sources/Cella"
        )
    ]
)
