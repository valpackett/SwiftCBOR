// swift-tools-version:5.9

import PackageDescription

let package = Package(
	name: "SwiftCBOR",
	platforms: [.macOS(.v10_15), .iOS(.v14), .watchOS(.v9)],
	products: [
		.library(name: "SwiftCBOR", targets: ["SwiftCBOR"])
	],
	dependencies: [
		.package(url: "https://github.com/scytales-com/swift-collections.git", from: "1.1.0"),
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
