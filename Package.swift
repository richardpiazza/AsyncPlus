// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncPlus",
    platforms: [
        .macOS(.v13),
        .macCatalyst(.v16),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "AsyncPlus",
            targets: [
                "AsyncPlus",
            ],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swhitty/swift-mutex.git", from: "0.0.6"),
    ],
    targets: [
        .target(
            name: "AsyncPlus",
            dependencies: [
                .product(name: "Mutex", package: "swift-mutex"),
            ],
        ),
        .testTarget(
            name: "AsyncPlusTests",
            dependencies: [
                "AsyncPlus",
            ],
        ),
    ],
    swiftLanguageModes: [
        .v6,
        .v5,
    ],
)

for target in package.targets {
    var settings = target.swiftSettings ?? []
    settings.append(contentsOf: [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("StrictConcurrency=complete"),
    ])
    target.swiftSettings = settings
}
