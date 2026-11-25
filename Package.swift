// swift-tools-version:5.5

import PackageDescription

var dependencies: [Package.Dependency] = []
var testDependencies: [Target.Dependency] = ["SwiftCBOR"]

#if compiler(>=6.2)
dependencies.append(
    .package(url: "https://github.com/x-sheep/swift-property-based.git", from: "2.0.1")
)
testDependencies.append(
    .product(name: "PropertyBased", package: "swift-property-based")
)
#endif

let package = Package(
    name: "SwiftCBOR",
    platforms: [.macOS(.v10_13), .iOS(.v13), .tvOS(.v13), .macCatalyst(.v13), .watchOS(.v8)],
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
