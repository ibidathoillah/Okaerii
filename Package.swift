// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Okaerii",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Okaerii", targets: ["Okaerii"])
    ],
    targets: [
        .executableTarget(
            name: "Okaerii",
            dependencies: [],
            path: "Sources/Okaerii",
            exclude: [
                "App/Info.plist"
            ],
            resources: [
                .copy("Audio"),
            ]
        )
    ]
)
