// swift-tools-version:6.2

import PackageDescription

let package = Package(
	name: "SwiftCBOR",
	platforms: [.macOS(.v15), .iOS(.v15), .tvOS(.v15), .macCatalyst(.v15), .watchOS(.v9)],
	products: [
		.library(name: "SwiftCBOR", targets: ["SwiftCBOR"])
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-collections.git", from: "1.7.3"),
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
