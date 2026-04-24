// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ClickerGame",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ClickerGame",
            targets: ["ClickerGame"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ClickerGame",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "ClickerGameTests",
            dependencies: ["ClickerGame"],
            path: "Tests"
        ),
    ]
)
