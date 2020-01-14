// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Bond",
    platforms: [
        .macOS(.v10_11), .iOS(.v8), .tvOS(.v9)
    ],
    products: [
        .library(name: "Bond", targets: ["Bond"])
    ],
    dependencies: [
        .package(url: "https://github.com/DeclarativeHub/ReactiveKit.git", .upToNextMajor(from: "3.15.6")),
        .package(url: "https://github.com/tonyarnold/Differ.git", .upToNextMajor(from: "1.4.4"))
    ],
    targets: [
        .target(name: "BNDProtocolProxyBase"),
        .target(name: "Bond", dependencies: ["BNDProtocolProxyBase", "ReactiveKit", "Differ"]),
        .testTarget(name: "BondTests", dependencies: ["Bond", "ReactiveKit"])
    ]
)
