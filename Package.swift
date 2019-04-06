// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "PandaMom",
    dependencies: [
        .package(url: "https://github.com/sharplet/Regex.git", from: "2.0.0"),
    ],
    targets: [
        .target(name: "PandaMom", dependencies: ["Regex"]),
    ]
)
