// swift-tools-version:5.5

import PackageDescription

var dependencies: [Package.Dependency] = []
var testDependencies: [Target.Dependency] = ["SwiftCBOR"]

#if compiler(>=6.2)
dependencies.append(
    .package(
        url: "https://github.com/hamchapman/swift-property-based.git",
        revision: "169a57520a649c3569c6a6136f518eed8a39a8b2"
    )
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
