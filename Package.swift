// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "subMission",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "TransmissionRPC", targets: ["TransmissionRPC"]),
        .executable(name: "subMission", targets: ["subMission"]),
    ],
    targets: [
        .target(
            name: "TransmissionRPC",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "subMission",
            dependencies: ["TransmissionRPC"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
