// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Bond",
    products: [
        .library(name: "Bond", targets: ["Bond"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveKit/ReactiveKit.git", .upToNextMajor(from: "3.9.0")),
        .package(url: "https://github.com/tonyarnold/Differ.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "BNDProtocolProxyBase"),
        .target(name: "Bond", dependencies: ["BNDProtocolProxyBase", "ReactiveKit", "Differ"]),
        .testTarget(name: "BondTests", dependencies: ["Bond"])
    ]
)
