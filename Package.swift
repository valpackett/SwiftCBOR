// swift-tools-version:5.5

import PackageDescription

var dependencies: [Package.Dependency] = []
var testDependencies: [Target.Dependency] = ["SwiftCBOR"]

#if compiler(>=6.2)
dependencies.append(
    .package(
        url: "https://github.com/x-sheep/swift-property-based.git",
        revision: "fbc0b8b83afc91e159ed62ba2024da8029ab7c97"
    )
)
testDependencies.append(
    .product(name: "PropertyBased", package: "swift-property-based")
)
#endif

let package = Package(
    name: "SwiftCBOR",
    platforms: [.macOS(.v12), .iOS(.v15), .tvOS(.v15), .macCatalyst(.v15), .watchOS("9.0")],
    products: [
        .library(name: "SwiftCBOR", targets: ["SwiftCBOR"])
    ],
    dependencies: dependencies,
    targets: [
        .target(name: "SwiftCBOR", path: "Sources", exclude: ["Info.plist"], resources: [.copy("PrivacyInfo.xcprivacy")]),
        .testTarget(
            name: "SwiftCBORTests",
            dependencies: testDependencies,
            path: "Tests",
            exclude: ["Info.plist"]
        )
    ]
)
