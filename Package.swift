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
        ),
        .library(
            name: "OryUI",
            targets: ["OryUI"]
        )
    ],
    dependencies: [
        .package(name: "OryClient", path: "Dependencies/OryClient"),
        .package(name: "SecureStorage", path: "Dependencies/SecureStorage")
    ],
    targets: [
        .target(
            name: "OryAuth",
            dependencies: [
                "OryClient",
                "SecureStorage"
            ]
        ),
        .target(
            name: "OryUI",
            dependencies: [
                "OryAuth"
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
