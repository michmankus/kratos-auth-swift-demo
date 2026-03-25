// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "OrySwiftSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "OryAuth",
            targets: ["OryAuth"]
        )
    ],
    dependencies: [
        .package(name: "OryClient", path: "Dependencies/OryClient")
    ],
    targets: [
        .target(
            name: "OryAuth",
            dependencies: [
                "OryClient"
            ]
        ),
        .testTarget(
            name: "OryAuthTests",
            dependencies: [
                "OryAuth"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
