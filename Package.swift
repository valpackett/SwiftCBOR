// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SwiftCBOR",
    platforms: [.macOS(.v10_10), .iOS(.v10)],
    products: [
        .library(name: "SwiftCBOR", targets: ["SwiftCBOR"])
    ],
    targets: [
        .target(name: "SwiftCBOR", path: "Sources", exclude: ["Info.plist"]),
        .testTarget(
            name: "SwiftCBORTests",
            dependencies: ["SwiftCBOR"],
            path: "Tests",
            exclude: ["Info.plist"]
        )
    ]
)
