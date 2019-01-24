// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Bond",
    products: [
        .library(name: "Bond", targets: ["Bond"])
    ],
    dependencies: [
        .package(url: "https://github.com/tonyarnold/ReactiveKit.git", .branch("swift-5.0")),
        .package(url: "https://github.com/tonyarnold/Differ.git", .branch("swift-5.0"))
    ],
    targets: [
        .target(name: "BNDProtocolProxyBase"),
        .target(name: "Bond", dependencies: ["BNDProtocolProxyBase", "ReactiveKit", "Differ"]),
        .testTarget(name: "BondTests", dependencies: ["Bond"])
    ]
)
