// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ClickerApp",
    platforms: [.iOS(.v15)],
    products: [
        .executable(name: "ClickerApp", targets: ["ClickerApp"])
    ],
    targets: [
        .executableTarget(
            name: "ClickerApp",
            dependencies: [],
            path: ".",
            sources: ["ClickerApp.swift"],
            resources: [
                .copy("Resources/Info.plist"),
                .copy("Resources/LaunchScreen.storyboard")
            ],
            swiftSettings: [
                .define("IOS_APP")
            ]
        )
    ]
)
