// swift-tools-version:6.0

import PackageDescription

let package = Package(
	name: "SwiftCBOR",
	platforms: [.macOS(.v10_13), .iOS(.v13), .tvOS(.v13), .macCatalyst(.v13), .watchOS(.v8)],
	products: [
		.library(name: "SwiftCBOR", targets: ["SwiftCBOR"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-collections.git", from: "1.6.0"),
	],
	targets: [
		.target(name: "SwiftCBOR", dependencies: [.product(name: "Collections", package: "swift-collections")],
						path: "Sources", exclude: ["Info.plist"]),
		.testTarget(
			name: "SwiftCBORTests",
			dependencies: ["SwiftCBOR"],
			path: "Tests",
			exclude: ["Info.plist"]
		)
	]
)
