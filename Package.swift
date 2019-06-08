// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "SwiftCBOR",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v8),
        .tvOS(.v9),
        .watchOS(.v3),
    ],
    products: [
        .library(name: "SwiftCBOR", targets: ["SwiftCBOR"])
    ],
    targets: [
        .target(name: "SwiftCBOR"),
        .testTarget(name: "SwiftCBORTests", dependencies: ["SwiftCBOR"]),
    ]
)
