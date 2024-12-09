// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SwiftCBOR",
    platforms: [.macOS(.v10_13), .iOS(.v13), .tvOS(.v13), .macCatalyst(.v13)],
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
