// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "SwiftCBOR",
    products: [
        .library(name: "SwiftCBOR", targets: ["SwiftCBOR"])
    ],
    targets: [
        .target(name: "SwiftCBOR"),
        .testTarget(name: "SwiftCBORTests", dependencies: ["SwiftCBOR"]),
    ]
)
