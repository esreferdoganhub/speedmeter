// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeedMeter",
    platforms: [
        .macOS(.v13)  // SwiftUI grafik için minimum macOS 13
    ],
    products: [
        .executable(
            name: "SpeedMeter",
            targets: ["SpeedMeter"])
    ],
    targets: [
        .executableTarget(
            name: "SpeedMeter",
            dependencies: [],
            path: "Sources/SpeedMeter"
        )
    ]
)
