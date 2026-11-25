// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SwiftCBOR",
    platforms: [.macOS(.v10_13), .iOS(.v13), .tvOS(.v13), .macCatalyst(.v13), .watchOS(.v8)],
    products: [
        .library(name: "SwiftCBOR", targets: ["SwiftCBOR"])
    ],
    dependencies: [
        .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0")
    ],
    targets: [
        .target(name: "SwiftCBOR", path: "Sources", exclude: ["Info.plist"], resources: [.copy("PrivacyInfo.xcprivacy")]),
        .testTarget(
            name: "SwiftCBORTests",
            dependencies: ["SwiftCBOR", "SwiftCheck"],
            path: "Tests",
            exclude: ["Info.plist"]
        )
    ]
)
