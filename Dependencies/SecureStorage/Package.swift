// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SecureStorage",
    defaultLocalization: .init(stringLiteral: "en"),
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "SecureStorage",
            targets: ["SecureStorage"]
        )
    ],
    targets: [
        .target(
            name: "SecureStorage",
            swiftSettings: [
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault")
            ]
        ),
        .testTarget(
            name: "SecureStorageTests",
            dependencies: [
                "SecureStorage"
            ],
            swiftSettings: [
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault")
            ]
        )
    ]
)
